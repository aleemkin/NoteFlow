import 'package:flutter/material.dart';
import 'package:noteflow/features/shell/presentation/widgets/vault_loading_overlay.dart';

export 'package:noteflow/features/shell/presentation/widgets/vault_loading_overlay.dart';

/// Modal loading overlay displayed during mobile vault initialization and opening.
class MobileLoadingOverlay extends StatelessWidget {
  const MobileLoadingOverlay({
    super.key,
    required this.message,
    this.title = 'Opening Vault',
    this.progress,
    this.subtitle,
  });

  final String message;
  final String title;
  final double? progress;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return VaultLoadingOverlay(
      title: title,
      message: message,
      progress: progress,
      subtitle: subtitle,
    );
  }
}
