import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noteflow/features/support/data/production_support_service.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';

/// Service defining interactions for supporting NoteFlow via
/// Google Play In-App Billing (One-time Consumables) and Google Mobile Ads (Rewarded Video Ads).
abstract class SupportService {
  /// Current list of available support tiers.
  List<SupportTier> get tiers;

  /// Stream of successful purchase events for UI celebration dialogs.
  Stream<SupportTier> get onPurchaseSuccess;

  /// Stream of purchase errors.
  Stream<String> get onPurchaseError;

  /// Initializes store products and preloads resources.
  Future<void> initialize();

  /// Initiates purchase flow for the specified [tier].
  Future<bool> sendTip(SupportTier tier);

  /// Displays a rewarded video ad.
  Future<bool> showRewardedAd({
    required VoidCallback onRewarded,
    Function(String reason)? onFailed,
  });

  /// Global singleton instance accessor.
  static SupportService instance = ProductionSupportService();
}


