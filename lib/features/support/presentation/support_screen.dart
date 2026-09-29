import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/features/support/data/support_service.dart';
import 'package:noteflow/features/support/domain/support_tier.dart';
import 'package:noteflow/features/support/presentation/widgets/contribution_success_dialog.dart';
import 'package:noteflow/features/support/presentation/widgets/support_ad_section.dart';
import 'package:noteflow/features/support/presentation/widgets/support_faq_section.dart';
import 'package:noteflow/features/support/presentation/widgets/support_hero_header.dart';
import 'package:noteflow/features/support/presentation/widgets/support_money_section.dart';

/// Full-page dedicated screen allowing users to support NoteFlow
/// through direct tips (one-time coffee purchases) or free rewarded sponsor ads.
class SupportScreen extends StatefulWidget {
  final SupportService? supportService;

  const SupportScreen({super.key, this.supportService});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late final SupportService _service;
  late SupportTier _selectedTier;
  bool _isPurchasing = false;
  bool _isLoadingAd = false;
  StreamSubscription<SupportTier>? _purchaseSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _service = widget.supportService ?? SupportService.instance;
    _selectedTier = _service.tiers.firstWhere(
      (t) => t.isPopular,
      orElse: () => _service.tiers.first,
    );

    // Initialize products from Google Play and update UI with localized prices
    _service.initialize().then((_) {
      if (mounted) {
        setState(() {
          _selectedTier = _service.tiers.firstWhere(
            (t) => t.id == _selectedTier.id,
            orElse: () => _service.tiers.first,
          );
        });
      }
    });

    // Listen for verified purchases to celebrate
    _purchaseSub = _service.onPurchaseSuccess.listen((tier) {
      if (!mounted) return;
      ContributionSuccessDialog.show(
        context,
        iconEmoji: tier.emoji,
        title: 'Thank you for your coffee!',
        message:
            'Your support (${tier.priceDisplay}) fuels development of NoteFlow. '
            'You\'ve helped keep this project independent and offline-first!',
      );
    });
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }

  void _onSelectTier(SupportTier tier) {
    setState(() {
      _selectedTier = tier;
    });
  }

  Future<void> _handlePayTier() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    try {
      await _service.sendTip(_selectedTier);
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _handleWatchAd() async {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    try {
      await _service.showRewardedAd(
        onRewarded: () async {
          if (!mounted) return;
          await ContributionSuccessDialog.show(
            context,
            iconEmoji: '🎉',
            title: 'Ad Reward Claimed!',
            message:
                'Thank you for watching a sponsor ad! Your support directly '
                'funds independent open development of NoteFlow.',
          );
        },
        onFailed: (reason) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sponsor Ad: $reason'),
              backgroundColor: const Color(0xFF1F6FEB),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingAd = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceNavbar,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Support NoteFlow',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDFE2EB),
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderSubtle, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Hero Header
                  const SupportHeroHeader(),
                  const SizedBox(height: 48),

                  // Section 1: Contribute with Money (Coffee)
                  SupportMoneySection(
                    tiers: _service.tiers,
                    selectedTier: _selectedTier,
                    onSelectTier: _onSelectTier,
                    isPurchasing: _isPurchasing,
                    onPayTier: _handlePayTier,
                  ),
                  const SizedBox(height: 32),

                  // Section 2: Contribute with Ad
                  SupportAdSection(
                    isLoadingAd: _isLoadingAd,
                    onWatchAd: _handleWatchAd,
                  ),
                  const SizedBox(height: 32),

                  // Section 3: Transparency & FAQ
                  const SupportFaqSection(),
                  const SizedBox(height: 28),

                  // Footer Note
                  Center(
                    child: Text(
                      'NoteFlow is 100% offline & local-first. Made with care for thinkers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
