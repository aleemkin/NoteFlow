import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:noteflow/core/notifications/app_notification.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';

/// Manages Google Play In-App Billing (one-time consumable purchases) for NoteFlow tips.
///
/// Handles querying product details, listening to the purchase stream, acknowledging
/// and consuming purchases (so consumables can be repurchased as coffee tips),
/// and broadcasting purchase success/error events.
class PlayBillingManager {
  final InAppPurchase? _iap;
  final StreamController<SupportTier> _purchaseController;
  final StreamController<String> _errorController;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Map<String, ProductDetails> _cachedProducts = {};
  List<SupportTier> _tiers = SupportTier.defaultTiers;

  PlayBillingManager({
    InAppPurchase? iap,
    StreamController<SupportTier>? purchaseController,
    StreamController<String>? errorController,
  }) : _iap =
           iap ??
           (Platform.environment.containsKey('FLUTTER_TEST')
               ? null
               : InAppPurchase.instance),
       _purchaseController =
           purchaseController ?? StreamController<SupportTier>.broadcast(),
       _errorController =
           errorController ?? StreamController<String>.broadcast() {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _initializeBillingStream();
      initialize();
    }
  }

  /// Stream of successfully completed purchases for UI celebration.
  Stream<SupportTier> get onPurchaseSuccess => _purchaseController.stream;

  /// Stream of purchase errors for logging and alerts.
  Stream<String> get onPurchaseError => _errorController.stream;

  /// Current list of available support tiers with localized store pricing if queried.
  List<SupportTier> get tiers => _tiers;

  /// Initializes store connection and queries localized pricing from Google Play.
  Future<void> initialize() async {
    final iap = _iap;
    if (iap == null) return;

    try {
      final available = await iap.isAvailable();
      if (!available) {
        debugPrint(
          'PlayBillingManager: InAppPurchase is currently unavailable',
        );
        return;
      }

      final ids = SupportTier.defaultTiers
          .map((t) => t.googlePlayProductId)
          .toSet();
      final response = await iap.queryProductDetails(ids);

      if (response.error != null) {
        debugPrint(
          'PlayBillingManager query error: ${response.error!.message} (${response.error!.code})',
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'PlayBillingManager: Product IDs not found in Play Store: ${response.notFoundIDs}',
        );
      }

      if (response.productDetails.isNotEmpty) {
        final Map<String, ProductDetails> map = {};
        for (final p in response.productDetails) {
          map[p.id] = p;
        }
        _cachedProducts = map;

        // Update tiers with localized pricing directly from Google Play
        _tiers = SupportTier.defaultTiers.map((tier) {
          final googleProduct = map[tier.googlePlayProductId];
          if (googleProduct != null) {
            return SupportTier(
              id: tier.id,
              name: tier.name,
              emoji: tier.emoji,
              priceDisplay: googleProduct.price,
              priceAmount: googleProduct.rawPrice,
              description: tier.description,
              isPopular: tier.isPopular,
              googlePlayProductId: tier.googlePlayProductId,
            );
          }
          return tier;
        }).toList();
      }
    } catch (e) {
      debugPrint('PlayBillingManager initialization query error: $e');
    }
  }

  void _initializeBillingStream() {
    final iap = _iap;
    if (iap == null) return;

    _purchaseSubscription = iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (dynamic error) {
        debugPrint('PlayBillingManager: PurchaseStream error: $error');
        _errorController.add('Billing error: $error');
      },
    );
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    final iap = _iap;
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Acknowledge & consume purchase so user can buy this coffee tier again
        if (purchase.pendingCompletePurchase && iap != null) {
          await iap.completePurchase(purchase);
        }

        final tier = _tiers.firstWhere(
          (t) => t.googlePlayProductId == purchase.productID,
          orElse: () => SupportTier.defaultTiers.first,
        );

        _purchaseController.add(tier);

        AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Thank you for your coffee! ${tier.name} received.'),
            backgroundColor: const Color(0xFF238636),
          ),
        );
      } else if (purchase.status == PurchaseStatus.error) {
        final errorMsg =
            purchase.error?.message ?? 'Purchase was not completed';
        debugPrint('PlayBillingManager: Purchase error: $errorMsg');
        _errorController.add(errorMsg);
        AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Purchase could not be completed: $errorMsg'),
            backgroundColor: const Color(0xFFF85149),
          ),
        );
      }
    }
  }

  /// Initiates a consumable purchase for [tier].
  Future<bool> sendTip(SupportTier tier) async {
    final iap = _iap;
    if (iap == null) return false;

    try {
      final available = await iap.isAvailable();
      if (!available) {
        AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Google Play Store is currently unavailable. Please verify Google Play Services.',
            ),
            backgroundColor: Color(0xFFF85149),
          ),
        );
        return false;
      }

      ProductDetails? product = _cachedProducts[tier.googlePlayProductId];

      if (product == null) {
        // Refresh product query if not cached
        final response = await iap.queryProductDetails({
          tier.googlePlayProductId,
        });
        if (response.error != null) {
          AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Google Play Billing: ${response.error!.message}'),
              backgroundColor: const Color(0xFFF85149),
            ),
          );
          return false;
        }
        if (response.productDetails.isNotEmpty) {
          product = response.productDetails.first;
          _cachedProducts[tier.googlePlayProductId] = product;
        }
      }

      if (product == null) {
        // Clear and precise explanation for the developer / tester
        AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Product "${tier.name}" (${tier.googlePlayProductId}) is not active yet in Google Play Console under One-time products, or tester account is not linked.',
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: const Color(0xFF1F6FEB),
          ),
        );
        return false;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      return await iap.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('PlayBillingManager: sendTip exception: $e');
      AppNotification.scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Error initiating purchase: $e'),
          backgroundColor: const Color(0xFFF85149),
        ),
      );
      return false;
    }
  }

  /// Disposes active purchase streams.
  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseController.close();
    _errorController.close();
  }
}
