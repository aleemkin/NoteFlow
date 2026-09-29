import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:noteflow/features/support/data/admob_rewarded_manager.dart';
import 'package:noteflow/features/support/data/play_billing_manager.dart';
import 'package:noteflow/features/support/data/support_service.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';

/// Production implementation of [SupportService].
///
/// Integrates and orchestrates:
/// - [PlayBillingManager]: Google Play In-App Billing for one-time tip consumables.
/// - [AdmobRewardedManager]: Google Mobile Ads for opt-in rewarded video ads.
class ProductionSupportService extends SupportService {
  final PlayBillingManager _billingManager;
  final AdmobRewardedManager _adManager;

  /// Production AdMob Rewarded Video Ad Unit ID.
  static const String rewardedAdUnitId =
      AdmobRewardedManager.defaultRewardedAdUnitId;

  ProductionSupportService({
    InAppPurchase? iap,
    PlayBillingManager? billingManager,
    AdmobRewardedManager? adManager,
  })  : _billingManager =
            billingManager ?? PlayBillingManager(iap: iap),
        _adManager = adManager ?? AdmobRewardedManager();

  @override
  Stream<SupportTier> get onPurchaseSuccess => _billingManager.onPurchaseSuccess;

  @override
  Stream<String> get onPurchaseError => _billingManager.onPurchaseError;

  @override
  List<SupportTier> get tiers => _billingManager.tiers;

  @override
  Future<void> initialize() => _billingManager.initialize();

  @override
  Future<bool> sendTip(SupportTier tier) => _billingManager.sendTip(tier);

  @override
  Future<bool> showRewardedAd({
    required VoidCallback onRewarded,
    Function(String reason)? onFailed,
  }) =>
      _adManager.showRewardedAd(
        onRewarded: onRewarded,
        onFailed: onFailed,
      );

  /// Preloads a rewarded video ad for fast playback.
  void preloadRewardedAd() => _adManager.preloadRewardedAd();

  /// Disposes background billing streams and loaded ad instances.
  void dispose() {
    _billingManager.dispose();
    _adManager.dispose();
  }
}
