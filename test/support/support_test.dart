import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/support/support.dart';

class FakeTestSupportService extends SupportService {
  final StreamController<SupportTier> _purchaseController =
      StreamController<SupportTier>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  final List<SupportTier> _tiers = SupportTier.defaultTiers;

  @override
  List<SupportTier> get tiers => _tiers;

  @override
  Stream<SupportTier> get onPurchaseSuccess => _purchaseController.stream;

  @override
  Stream<String> get onPurchaseError => _errorController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> sendTip(SupportTier tier) async {
    _purchaseController.add(tier);
    return true;
  }

  @override
  Future<bool> showRewardedAd({
    required VoidCallback onRewarded,
    Function(String reason)? onFailed,
  }) async {
    onRewarded();
    return true;
  }

  void dispose() {
    _purchaseController.close();
    _errorController.close();
  }
}

void main() {
  group('Support Feature Unit & Widget Tests', () {
    late FakeTestSupportService supportService;

    setUp(() {
      supportService = FakeTestSupportService();
    });

    tearDown(() {
      supportService.dispose();
    });

    test('SupportTier default configurations', () {
      expect(supportService.tiers.length, equals(4));

      final productIds =
          supportService.tiers.map((t) => t.googlePlayProductId).toList();
      expect(productIds, containsAll([
        'noteflow_tip_espresso',
        'noteflow_tip_croissant',
        'noteflow_tip_lunch',
        'noteflow_tip_patron',
      ]));

      final popularTier =
          supportService.tiers.firstWhere((t) => t.isPopular);
      expect(popularTier.name, contains('Croissant'));
    });

    test('ProductionSupportService initial state and delegates', () {
      final service = ProductionSupportService();
      expect(service.tiers.length, equals(4));
      expect(ProductionSupportService.rewardedAdUnitId, isNotEmpty);
      service.dispose();
    });

    testWidgets('SupportHeroHeader renders icon and heading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupportHeroHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy Me a Coffee'), findsOneWidget);
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);
      expect(
        find.textContaining('fast, local-first notebook'),
        findsOneWidget,
      );
    });

    testWidgets('SupportTierCard renders details, popular tag, and taps', (
      tester,
    ) async {
      var selected = false;
      const tier = SupportTier(
        id: 'test_tier',
        name: 'Test Coffee',
        priceDisplay: '\$3.50',
        priceAmount: 3.50,
        emoji: '☕',
        description: 'Test coffee description',
        isPopular: true,
        googlePlayProductId: 'test_product',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportTierCard(
              tier: tier,
              isSelected: true,
              onTap: () => selected = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Coffee'), findsOneWidget);
      expect(find.text('\$3.50'), findsOneWidget);
      expect(find.text('☕'), findsOneWidget);
      expect(find.text('Test coffee description'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);

      await tester.tap(find.byType(SupportTierCard));
      await tester.pumpAndSettle();

      expect(selected, isTrue);
    });

    testWidgets('SupportMoneySection renders tiers and triggers pay', (
      tester,
    ) async {
      var payTriggered = false;
      final tiers = SupportTier.defaultTiers;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportMoneySection(
              tiers: tiers,
              selectedTier: tiers[1],
              onSelectTier: (_) {},
              isPurchasing: false,
              onPayTier: () => payTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTRIBUTE WITH MONEY'), findsOneWidget);
      expect(find.text('Coffee & Croissant'), findsOneWidget);

      // Tap pay button
      await tester.tap(find.text('Send Coffee & Croissant (\$4.99)'));
      await tester.pumpAndSettle();

      expect(payTriggered, isTrue);
    });

    testWidgets('SupportAdSection renders loading and ready states', (
      tester,
    ) async {
      var adTriggered = false;

      // 1. Ready state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportAdSection(
              isLoadingAd: false,
              onWatchAd: () => adTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contribute for Free'), findsOneWidget);
      expect(find.text('100% Free'), findsOneWidget);
      expect(find.text('Watch Sponsor Ad (~30s)'), findsOneWidget);

      await tester.tap(find.text('Watch Sponsor Ad (~30s)'));
      await tester.pumpAndSettle();
      expect(adTriggered, isTrue);

      // 2. Loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SupportAdSection(
              isLoadingAd: true,
              onWatchAd: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading Sponsor Ad...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('SupportFaqSection renders FAQ items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SupportFaqSection(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TRANSPARENCY & PROMISES'), findsOneWidget);
      expect(find.text('Are any NoteFlow features paywalled?'), findsOneWidget);
      expect(find.text('How are tips and ads utilized?'), findsOneWidget);
      expect(find.text('How is privacy protected?'), findsOneWidget);
    });

    testWidgets('WelcomeSupportCard renders coffee cup and triggers onTap', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeSupportCard(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(
        find.text('Contribute with a tip or support for free by watching an ad'),
        findsOneWidget,
      );

      await tester.tap(find.byType(WelcomeSupportCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('SupportScreen renders hero, tiers, and sends tip', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SupportScreen(supportService: supportService),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and hero
      expect(find.text('Support NoteFlow'), findsOneWidget);
      expect(find.text('Buy Me a Coffee'), findsOneWidget);

      // Support tiers
      expect(find.text('CONTRIBUTE WITH MONEY'), findsOneWidget);
      expect(find.text('Quick Espresso'), findsOneWidget);
      expect(find.text('Coffee & Croissant'), findsOneWidget);
      expect(find.text('Developer Lunch'), findsOneWidget);
      expect(find.text('NoteFlow Patron'), findsOneWidget);

      // Ad section
      expect(find.text('Contribute for Free'), findsOneWidget);
      expect(find.text('Watch Sponsor Ad (~30s)'), findsOneWidget);

      // Select another tier
      await tester.tap(find.text('Developer Lunch'));
      await tester.pumpAndSettle();

      expect(find.text('Send Developer Lunch (\$9.99)'), findsOneWidget);

      // Tap Send tip button -> triggers sendTip directly
      await tester.tap(find.text('Send Developer Lunch (\$9.99)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Verify celebratory modal appears
      expect(find.text('Thank you for your coffee!'), findsOneWidget);
      expect(find.text('You\'re Awesome!'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('You\'re Awesome!'));
      await tester.pumpAndSettle();
    });

    testWidgets('SupportScreen ad flow launches and credits reward', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: SupportScreen(supportService: supportService),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Watch Sponsor Ad button
      await tester.scrollUntilVisible(
        find.text('Watch Sponsor Ad (~30s)'),
        200,
      );
      await tester.tap(find.text('Watch Sponsor Ad (~30s)'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Reward success modal
      expect(find.text('Ad Reward Claimed!'), findsOneWidget);
      await tester.tap(find.text('You\'re Awesome!'));
      await tester.pumpAndSettle();
    });
  });
}
