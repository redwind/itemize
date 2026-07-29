import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Constants ---

// Nothing here caps what a free user may do. Scanning is on-device and costs
// nothing to run, storing items costs nothing to run, and charging for either
// would be charging for the owner's own work. Pro is the report, the backup and
// the lock -- things the app does for them.
const String kProEntitlementId = 'pro_features'; // RevenueCat Entitlement ID

// --- RevenueCat API keys ---
//
// Public SDK keys, meant to ship inside the binary. Overridable at build time so
// a build can be pointed at another store without a code change:
//   flutter build ipa --dart-define=REVENUECAT_IOS_KEY=appl_xxx
//   flutter build appbundle --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
//
// To exercise the paywall on a simulator without real money, override with the
// Test Store key, which only ever simulates a purchase:
//   flutter run --dart-define=REVENUECAT_IOS_KEY=test_ugBFtkQlkIDRDgEkZvddgVorXDE
const String _kIosKey = String.fromEnvironment(
  'REVENUECAT_IOS_KEY',
  defaultValue: 'appl_WhvgPPcGPVNKesOtkJJlyhwzKVL',
);
const String _kAndroidKey = String.fromEnvironment(
  'REVENUECAT_ANDROID_KEY',
  defaultValue: 'goog_TvmnRsEhIjHTpjeDXgYBwmHQkQo',
);

/// Keys that only ever simulate a purchase.
bool _isTestStoreKey(String key) => key.startsWith('test_');

/// What happened on a purchase, restore or store-connection attempt.
///
/// Deliberately not a String: a notifier that renders its own English cannot
/// be translated when the language changes underneath it, and turns a money
/// screen into a UI concern it has no business owning. Each value here has a
/// matching AppLocalizations key, translated at the point of display (the
/// paywall) rather than at the point of decision (this file).
enum ProOutcome {
  /// The SDK never configured, or an offering could not be loaded -- nothing
  /// about the customer's account, just the store not answering right now.
  storeUnavailable,

  /// Ask to Buy, or a bank 2FA step. The charge may still land later; this is
  /// not a failure and must not be reported through the error slot.
  purchasePending,

  purchaseCancelled,

  /// Catch-all for a purchase that failed for a reason with no more specific
  /// outcome of its own.
  purchaseFailed,

  /// The store says this was already bought, but under an app user id
  /// [restorePurchases] could not reconcile to this install.
  purchaseAlreadyOwnedUnlinked,

  purchaseSucceeded,

  restoredToPro,

  /// Restore succeeded as an operation but found no entitlement to grant.
  restoredNothingFound,

  restoreFailed,
}

// --- State Class ---
class ProState {
  final bool isPro;
  final bool isLoading;

  /// False when the SDK was never configured, so no purchase can be made.
  final bool isStoreAvailable;

  /// The package being sold, once the store has told us about it.
  ///
  /// Price and product type are read off this rather than written into the UI,
  /// so the paywall cannot advertise a figure the user will not be charged.
  final Package? proPackage;
  final ProOutcome? errorOutcome;
  final ProOutcome? successOutcome;

  /// The raw exception behind [errorOutcome], only ever populated when
  /// detailed-error debugging is toggled on (see [ProNotifier.toggleDetailedErrors]).
  /// Rides alongside the translated outcome rather than replacing it, so a
  /// debug build can show both what the customer sees and what actually broke.
  final String? errorDetail;

  const ProState({
    this.isPro = false,
    this.isLoading = false,
    this.isStoreAvailable = false,
    this.proPackage,
    this.errorOutcome,
    this.successOutcome,
    this.errorDetail,
  });

  ProState copyWith({
    bool? isPro,
    bool? isLoading,
    bool? isStoreAvailable,
    Package? proPackage,
    ProOutcome? errorOutcome,
    bool clearErrorOutcome = false,
    ProOutcome? successOutcome,
    bool clearSuccessOutcome = false,
    String? errorDetail,
    bool clearErrorDetail = false,
  }) {
    return ProState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      proPackage: proPackage ?? this.proPackage,
      errorOutcome:
          clearErrorOutcome ? null : (errorOutcome ?? this.errorOutcome),
      successOutcome:
          clearSuccessOutcome
              ? null
              : (successOutcome ?? this.successOutcome),
      errorDetail:
          clearErrorDetail ? null : (errorDetail ?? this.errorDetail),
    );
  }


  /// Localized price straight from the store, null until the offering loads.
  String? get priceString => proPackage?.storeProduct.priceString;

  /// Whether the product renews. Drives the paywall's fine print, which must
  /// not promise "no subscription" for something that in fact recurs.
  bool get isSubscription {
    final category = proPackage?.storeProduct.productCategory;
    return category == ProductCategory.subscription;
  }
}

// --- Provider ---
final proProvider = StateNotifierProvider<ProNotifier, ProState>((ref) {
  return ProNotifier();
});

// --- Notifier ---
class ProNotifier extends StateNotifier<ProState> {
  // No SharedPreferences here any more: the daily scan quota was the only thing
  // that needed it, and scanning is now on-device, free and unmetered. Pro
  // status itself comes from RevenueCat, which is the only honest source for it.
  ProNotifier() : super(const ProState()) {
    _init();
  }

  /// A notifier holding [initial] and never talking to a store.
  ///
  /// The ordinary constructor reaches for RevenueCat the moment it is built,
  /// which a widget test has no business doing and no way to answer. This is
  /// the seam that lets a test say "this user is Pro" or "the store is down"
  /// and then look at what the screen does about it.
  @visibleForTesting
  ProNotifier.withState(super.initial);

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _initRevenueCat();
    state = state.copyWith(isLoading: false);
  }

  /// The key to configure the SDK with, or null when none may be used.
  static String? _resolveApiKey() {
    final String key =
        Platform.isIOS
            ? _kIosKey
            : Platform.isAndroid
            ? _kAndroidKey
            : '';
    if (key.isEmpty) return null;

    // A Test Store key is useful on a simulator and unacceptable in a shipped
    // build, where it would look like it is selling while taking no money.
    if (_isTestStoreKey(key) && !kDebugMode) return null;

    return key;
  }

  Future<void> _initRevenueCat() async {
    final apiKey = _resolveApiKey();
    if (apiKey == null) {
      // Leaves isPro false and every purchase path disabled, rather than
      // running against a store that cannot charge.
      state = state.copyWith(
        isStoreAvailable: false,
        errorOutcome: ProOutcome.storeUnavailable,
      );
      return;
    }

    // Use a single try-catch block for the entire initialization
    try {
      // Debug only. In release these logs carry the app user id and the
      // receipt traffic into every customer's device log, which is nobody's
      // business but theirs.
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Entitlements can arrive long after the purchase call returned: a
      // deferred purchase ("Ask to Buy") is approved by a parent hours later,
      // and a purchase made on another device syncs whenever it syncs. Without
      // this listener the money is taken and the app stays locked until the
      // user thinks to restart it or find Restore Purchases.
      if (!_listenerAttached) {
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
        _listenerAttached = true;
      }

      // Verify connection by getting customer info immediately after configure
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      state = state.copyWith(isStoreAvailable: true, clearErrorOutcome: true);
      _updateProStatus(customerInfo);
      await _loadOffering();
    } catch (e) {
      if (kDebugMode) print("RevenueCat init failed: $e");
      // Whatever broke -- unreachable host, a store SDK rejecting the key --
      // it lands on the same "try again later" outcome the customer sees,
      // since none of the specific causes are things they can act on.
      _emitError(ProOutcome.storeUnavailable, e);
    }
  }

  /// Called by RevenueCat whenever entitlements change, from any source.
  void _onCustomerInfo(CustomerInfo info) {
    if (!mounted) return;
    final wasPro = state.isPro;
    _updateProStatus(info);
    if (!wasPro && state.isPro && state.successOutcome == null) {
      state = state.copyWith(successOutcome: ProOutcome.purchaseSucceeded);
    }
  }

  /// Tries the store again after a failed start.
  ///
  /// Without this a single flaky moment during the very first launch left
  /// `isStoreAvailable` false for the rest of the session, with a dead buy
  /// button and no way back short of force-quitting the app. Someone who
  /// arrived at the paywall willing to pay was simply turned away.
  Future<void> retryStoreConnection() async {
    if (state.isStoreAvailable || state.isLoading) return;
    state = state.copyWith(isLoading: true, clearErrorOutcome: true);
    await _initRevenueCat();
    state = state.copyWith(isLoading: false);
  }

  /// Fetches the package on offer so the paywall can price itself.
  ///
  /// A failure here is not surfaced as an error: the paywall degrades to
  /// showing no price, which is better than an alarming message on a screen the
  /// user may only be browsing.
  Future<void> _loadOffering() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return;

      // The lifetime package by name, not whatever happens to sit at position
      // zero. Picking by position means that the day a second package is added
      // -- for a price test, or a subscription experiment -- the dashboard's
      // ordering silently decides what every customer is charged for.
      final package =
          current.lifetime ??
          (current.availablePackages.isNotEmpty
              ? current.availablePackages.first
              : null);
      if (package == null) return;

      if (current.lifetime == null) {
        if (kDebugMode) {
          print(
            'No lifetime package in offering "${current.identifier}"; '
            'falling back to "${package.identifier}".',
          );
        }
      }
      state = state.copyWith(proPackage: package);
    } catch (e) {
      if (kDebugMode) print("Loading offerings failed: $e");
    }
  }

  /// [retryStoreConnection] runs the whole init again, and the listener would
  /// otherwise be added once per attempt.
  bool _listenerAttached = false;

  // Debug flag for release mode
  bool _showDetailedErrors = false;

  void toggleDetailedErrors() {
    _showDetailedErrors = !_showDetailedErrors;
  }

  /// Sets the error outcome the paywall will translate, plus the raw
  /// exception alongside it -- but only when detailed-error debugging is on.
  /// Outside of that, [error] is discarded entirely rather than stored and
  /// left unread, so a stray customer stack trace never sits in memory (or a
  /// crash report) for no reason.
  void _emitError(ProOutcome outcome, [Object? error]) {
    final detail = (error != null && _showDetailedErrors) ? '$error' : null;
    state = state.copyWith(
      errorOutcome: outcome,
      errorDetail: detail,
      clearErrorDetail: detail == null,
    );
  }

  Future<void> restorePurchases() async {
    if (!state.isStoreAvailable) {
      _emitError(ProOutcome.storeUnavailable);
      return;
    }
    try {
      state = state.copyWith(
        isLoading: true,
        clearErrorOutcome: true,
        clearSuccessOutcome: true,
        clearErrorDetail: true,
      );
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      if (customerInfo.entitlements.all[kProEntitlementId]?.isActive == true) {
        state = state.copyWith(successOutcome: ProOutcome.restoredToPro);
      } else {
        state = state.copyWith(successOutcome: ProOutcome.restoredNothingFound);
      }
    } on PlatformException catch (e) {
      _emitError(ProOutcome.restoreFailed, e);
    } catch (e) {
      _emitError(ProOutcome.restoreFailed, e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> purchasePro() async {
    if (!state.isStoreAvailable) {
      _emitError(ProOutcome.storeUnavailable);
      return;
    }
    try {
      state = state.copyWith(
        isLoading: true,
        clearErrorOutcome: true,
        clearSuccessOutcome: true,
        clearErrorDetail: true,
      );
      // Charge the very package the paywall quoted a price for. Re-fetching
      // here could pick up a different one and bill an amount the user was
      // never shown.
      if (state.proPackage == null) {
        await _loadOffering();
      }
      final package = state.proPackage;

      if (package != null) {
        CustomerInfo info =
            (await Purchases.purchase(
              PurchaseParams.package(package),
            )).customerInfo;
        _updateProStatus(info);
        state = state.copyWith(successOutcome: ProOutcome.purchaseSucceeded);
      } else {
        // No offering configured server-side, not a payment failure -- the
        // customer's card was never touched.
        _emitError(ProOutcome.storeUnavailable);
      }

      // Mock success for now since we don't have keys
      // state = state.copyWith(isPro: true);
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        // Owned according to the store, which is not the same as entitled
        // according to RevenueCat -- the two disagree whenever the purchase is
        // attached to a different app user id, which is what a reinstall or a
        // device transfer produces. Granting Pro locally here made the app
        // unlock for one session and lock itself again on the next launch,
        // after the report had been exported and the lock switched on. So ask
        // the server to reconcile it instead of taking the error code's word.
        await restorePurchases();
        if (!state.isPro) {
          state = state.copyWith(clearSuccessOutcome: true);
          _emitError(ProOutcome.purchaseAlreadyOwnedUnlinked, e);
        }
        return; // Skip the generic failure outcome below
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        // Ask to Buy, or a bank that wants a second factor. The charge may yet
        // go through, so this is not a failure and must not be reported as one.
        // _onCustomerInfo unlocks the app if and when approval arrives.
        state = state.copyWith(successOutcome: ProOutcome.purchasePending);
        return;
      } else if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        // Nothing to debug about a deliberate cancel, so no detail is kept.
        _emitError(ProOutcome.purchaseCancelled);
      } else {
        _emitError(ProOutcome.purchaseFailed, e);
      }
    } catch (e) {
      _emitError(ProOutcome.purchaseFailed, e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void _updateProStatus(CustomerInfo customerInfo) {
    final isPro =
        customerInfo.entitlements.all[kProEntitlementId]?.isActive ?? false;
    state = state.copyWith(isPro: isPro);
  }

  // Debug method
  Future<void> debugCancelPro() async {
    state = state.copyWith(
      isPro: false,
      clearSuccessOutcome: true,
      clearErrorOutcome: true,
      clearErrorDetail: true,
    );

    // Attempt to open the respective store's subscription management page
    try {
      if (Platform.isAndroid) {
        // App package name is typically needed for deep linking to specific subscriptions,
        // but this general URL takes them to the subscriptions page in Play Store.
        final url = Uri.parse(
          'https://play.google.com/store/account/subscriptions',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } else if (Platform.isIOS) {
        // This is the standard iOS URL to open the subscription management page
        final url = Uri.parse('https://apps.apple.com/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Could not open store to cancel subscription: $e');
    }
  }
}
