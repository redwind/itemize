import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:itemize/providers/settings_provider.dart'; // For sharedPreferencesProvider

// --- Constants ---
const int kFreeAssetLimit = 10;
const int kFreeScanLimit = 5;
const String kProEntitlementId = 'pro_features'; // RevenueCat Entitlement ID
const String kScanCountKey = 'daily_scan_count';
const String kScanDateKey = 'last_scan_date';

// --- State Class ---
class ProState {
  final bool isPro;
  final int dailyScanCount;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProState({
    this.isPro = false,
    this.dailyScanCount = 0,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ProState copyWith({
    bool? isPro,
    int? dailyScanCount,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ProState(
      isPro: isPro ?? this.isPro,
      dailyScanCount: dailyScanCount ?? this.dailyScanCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  bool get canScan => isPro || dailyScanCount < kFreeScanLimit;
}

// --- Provider ---
final proProvider = StateNotifierProvider<ProNotifier, ProState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProNotifier(prefs);
});

// --- Notifier ---
class ProNotifier extends StateNotifier<ProState> {
  final SharedPreferences _prefs;

  ProNotifier(this._prefs) : super(const ProState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    await _checkDailyScanReset();
    await _initRevenueCat();
    state = state.copyWith(isLoading: false);
  }

  Future<void> _initRevenueCat() async {
    // TODO: Replace with actual API Key from User or Config
    String apiKey;
    if (Platform.isIOS) {
      apiKey = 'test_ugBFtkQlkIDRDgEkZvddgVorXDE';
    } else if (Platform.isAndroid) {
      apiKey = 'goog_TvmnRsEhIjHTpjeDXgYBwmHQkQo';
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Use a single try-catch block for the entire initialization
    try {
      // FORCE DEBUG LOGS IN RELEASE MODE as per user request
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // Verify connection by getting customer info immediately after configure
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _updateProStatus(customerInfo);
    } catch (e) {
      if (kDebugMode) print("RevenueCat init failed: $e");
      String errorMsg = "Init failed";
      if (_showDetailedErrors) {
        errorMsg += ": $e";
      }
      state = state.copyWith(errorMessage: errorMsg);
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
    try {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
      );
      // In real app:
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        CustomerInfo info =
            (await Purchases.purchase(
              PurchaseParams.package(
                offerings.current!.availablePackages.first,
              ),
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

  // --- Scan Limits ---

  Future<void> _checkDailyScanReset() async {
    final lastScanStr = _prefs.getString(kScanDateKey);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (lastScanStr != todayStr) {
      // New day, reset count
      await _prefs.setInt(kScanCountKey, 0);
      await _prefs.setString(kScanDateKey, todayStr);
      state = state.copyWith(dailyScanCount: 0);
    } else {
      // Same day, load count
      final count = _prefs.getInt(kScanCountKey) ?? 0;
      state = state.copyWith(dailyScanCount: count);
    }
  }

  Future<void> incrementScanCount() async {
    if (state.isPro) return; // No updates needed if Pro

    final newCount = state.dailyScanCount + 1;
    state = state.copyWith(dailyScanCount: newCount);

    await _prefs.setInt(kScanCountKey, newCount);
    // Ensure date is set today if not already
    final now = DateTime.now();
    await _prefs.setString(kScanDateKey, "${now.year}-${now.month}-${now.day}");
  }

  // Method to check limit before action
  bool checkScanLimitReached() {
    if (state.isPro) return false;
    return state.dailyScanCount >= kFreeScanLimit;
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
