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

const String _kStoreUnavailableMessage =
    "Purchases are unavailable: this build has no live store key.";

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
  final String? errorMessage;
  final String? successMessage;

  const ProState({
    this.isPro = false,
    this.isLoading = false,
    this.isStoreAvailable = false,
    this.proPackage,
    this.errorMessage,
    this.successMessage,
  });

  ProState copyWith({
    bool? isPro,
    bool? isLoading,
    bool? isStoreAvailable,
    Package? proPackage,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ProState(
      isPro: isPro ?? this.isPro,
      isLoading: isLoading ?? this.isLoading,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      proPackage: proPackage ?? this.proPackage,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
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
        errorMessage: _kStoreUnavailableMessage,
      );
      return;
    }

    // Use a single try-catch block for the entire initialization
    try {
      // FORCE DEBUG LOGS IN RELEASE MODE as per user request
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Verify connection by getting customer info immediately after configure
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      state = state.copyWith(isStoreAvailable: true);
      _updateProStatus(customerInfo);
      await _loadOffering();
    } catch (e) {
      if (kDebugMode) print("RevenueCat init failed: $e");
      String errorMsg = "Init failed";
      if (_showDetailedErrors) {
        errorMsg += ": $e";
      }
      state = state.copyWith(errorMessage: errorMsg);
    }
  }

  /// Fetches the package on offer so the paywall can price itself.
  ///
  /// A failure here is not surfaced as an error: the paywall degrades to
  /// showing no price, which is better than an alarming message on a screen the
  /// user may only be browsing.
  Future<void> _loadOffering() async {
    try {
      final Offerings offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const [];
      if (packages.isNotEmpty) {
        state = state.copyWith(proPackage: packages.first);
      }
    } catch (e) {
      if (kDebugMode) print("Loading offerings failed: $e");
    }
  }

  // Debug flag for release mode
  bool _showDetailedErrors = false;

  void toggleDetailedErrors() {
    _showDetailedErrors = !_showDetailedErrors;
    state = state.copyWith(
      errorMessage: "Detailed errors: $_showDetailedErrors",
    );
  }

  Future<void> restorePurchases() async {
    if (!state.isStoreAvailable) {
      state = state.copyWith(errorMessage: _kStoreUnavailableMessage);
      return;
    }
    try {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      );
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      if (customerInfo.entitlements.all[kProEntitlementId]?.isActive == true) {
        state = state.copyWith(
          successMessage: "Purchases restored successfully. You are Pro!",
        );
      } else {
        state = state.copyWith(
          successMessage: "Purchases restored. No Pro entitlement found.",
        );
      }
    } on PlatformException catch (e) {
      String errorMsg = "Restore failed";
      if (_showDetailedErrors) {
        errorMsg += ": $e";
      } else {
        errorMsg = e.message ?? "Unknown device error";
      }
      state = state.copyWith(errorMessage: errorMsg);
    } catch (e) {
      String errorMsg = "Restore failed";
      if (_showDetailedErrors) {
        errorMsg += ": $e";
      }
      state = state.copyWith(errorMessage: errorMsg);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> purchasePro() async {
    if (!state.isStoreAvailable) {
      state = state.copyWith(errorMessage: _kStoreUnavailableMessage);
      return;
    }
    try {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
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
        state = state.copyWith(successMessage: "Success! You are now Pro.");
      } else {
        state = state.copyWith(
          errorMessage: "No offerings available. Please check configuration.",
        );
      }

      // Mock success for now since we don't have keys
      // state = state.copyWith(isPro: true);
    } on PlatformException catch (e) {
      String errorMsg = "Purchase failed";
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        errorMsg = "You already own this item.";
        // Automatically give them Pro if they already own it
        state = state.copyWith(isPro: true, successMessage: errorMsg);
        return; // Skip setting errorMessage
      } else if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        errorMsg = "Purchase cancelled.";
      } else {
        if (_showDetailedErrors) {
          errorMsg += ": $e";
        } else {
          errorMsg = e.message ?? errorMsg;
        }
      }
      state = state.copyWith(errorMessage: errorMsg);
    } catch (e) {
      String errorMsg = "Purchase failed";
      if (_showDetailedErrors) {
        errorMsg += ": $e";
      }
      state = state.copyWith(errorMessage: errorMsg);
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
  void toggleProStatus() {
    state = state.copyWith(isPro: !state.isPro);
  }

  // Debug method
  Future<void> debugCancelPro() async {
    state = state.copyWith(
      isPro: false,
      successMessage: null,
      errorMessage: null,
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
