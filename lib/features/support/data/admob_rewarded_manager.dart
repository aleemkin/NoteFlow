import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages Google Mobile Ads (AdMob) Rewarded Video Ads for NoteFlow.
///
/// NoteFlow is 100% banner-free and popup-free. Rewarded ads are strictly opt-in
/// and displayed on demand when the user voluntarily chooses to support NoteFlow
/// for free.
class AdmobRewardedManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  String? _lastAdError;

  /// Official Google Rewarded Video Test Ad Unit ID used as safe default.
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Rewarded Video Ad Unit ID.
  ///
  /// In release builds, loaded via `--dart-define-from-file=.env` or
  /// `--dart-define=ADMOB_REWARDED_AD_UNIT_ID=...`.
  /// Defaults to Google's official test ad unit ID when not specified.
  static const String defaultRewardedAdUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_AD_UNIT_ID',
    defaultValue: testRewardedAdUnitId,
  );

  final String adUnitId;

  AdmobRewardedManager({
    this.adUnitId = defaultRewardedAdUnitId,
  }) {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      preloadRewardedAd();
    }
  }

  /// Whether an ad request is actively in-flight.
  bool get isAdLoading => _isAdLoading;

  /// Whether an ad has been loaded and is primed for display.
  bool get isAdReady => _rewardedAd != null;

  /// Preloads a rewarded video ad so it is primed when requested.
  void preloadRewardedAd() {
    if (_rewardedAd != null || _isAdLoading) return;
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          _lastAdError = null;
          debugPrint(
            'AdmobRewardedManager: Rewarded ad preloaded successfully ($adUnitId)',
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          _lastAdError = '${error.message} (code ${error.code})';
          debugPrint(
            'AdmobRewardedManager: Rewarded ad failed to load: ${error.message} (code: ${error.code})',
          );
        },
      ),
    );
  }

  Future<bool> _loadRewardedAdAsync() async {
    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          _lastAdError = null;
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          _lastAdError = '${error.message} (code ${error.code})';
          debugPrint(
            'AdmobRewardedManager: Rewarded ad ($adUnitId) failed: ${error.message} (code: ${error.code})',
          );
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _isAdLoading = false;
        _lastAdError =
            'Ad request timed out. Please check your internet connection.';
        return false;
      },
    );
  }

  /// Displays the rewarded ad if preloaded, or loads on-demand.
  ///
  /// Invokes [onRewarded] when the user completes watching the video,
  /// and [onFailed] if ad loading or presentation encounters an error.
  Future<bool> showRewardedAd({
    required VoidCallback onRewarded,
    Function(String reason)? onFailed,
  }) async {
    if (_rewardedAd == null) {
      _isAdLoading = true;
      final loaded = await _loadRewardedAdAsync();

      if (!loaded || _rewardedAd == null) {
        onFailed?.call(
          _lastAdError ?? 'No ad currently available from Google AdMob',
        );
        return false;
      }
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onFailed?.call('${error.message} (code ${error.code})');
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return completer.future;
  }

  /// Disposes preloaded ads.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
