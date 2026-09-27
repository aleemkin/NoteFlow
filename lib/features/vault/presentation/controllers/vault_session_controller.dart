import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteflow/app/app_providers.dart';
import 'package:noteflow/features/vault/vault.dart';

/// Immutable state representing the active vault session.
class VaultSessionState {
  final VaultConfig? currentVault;
  final bool isLoading;
  final String? error;

  const VaultSessionState({
    this.currentVault,
    this.isLoading = false,
    this.error,
  });

  bool get isOpen => currentVault != null;
  String? get vaultName => currentVault?.displayName;

  VaultSessionState copyWith({
    VaultConfig? Function()? currentVault,
    bool? isLoading,
    String? Function()? error,
  }) {
    return VaultSessionState(
      currentVault: currentVault != null ? currentVault() : this.currentVault,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

/// Controller managing vault lifecycle (opening, creating, loading sample, closing).
class VaultSessionController extends StateNotifier<VaultSessionState> {
  final Ref _ref;

  VaultSessionController(this._ref) : super(const VaultSessionState());

  VaultManager get _manager => _ref.read(vaultManagerProvider);

  /// Initializes the vault on startup by restoring the last opened vault if available.
  Future<void> initStartupVault() async {
    if (state.isOpen) return;

    final pastPath = await VaultStateStorage.getLastVaultPath();
    if (pastPath != null) {
      try {
        await openVault(pastPath);
        return;
      } catch (_) {
        // Fall back to welcome screen if opening past vault failed
      }
    }
  }

  /// Opens a local vault located at [path].
  Future<void> openVault(String path) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _manager.openLocalVault(path);
      await VaultStateStorage.saveLastVaultPath(path);
      final vault = _manager.currentVault;
      _ref.read(currentVaultProvider.notifier).state = vault;
      state = state.copyWith(currentVault: () => vault, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
      rethrow;
    }
  }

  /// Unpacks and opens the interactive sample vault.
  Future<void> openSampleVault({
    bool? isMobile,
    void Function(String message, double? progress)? onProgress,
  }) async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      await _manager.openSampleVault(
        isMobile: isMobile,
        onProgress: onProgress,
      );
      final vault = _manager.currentVault;
      _ref.read(currentVaultProvider.notifier).state = vault;
      state = state.copyWith(currentVault: () => vault, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => e.toString());
      rethrow;
    }
  }

  /// Closes the current active vault and clears related sessions.
  Future<void> closeVault() async {
    _ref.read(currentVaultProvider.notifier).state = null;
    _ref.read(activeFolderControllerProvider.notifier).clear();
    _ref.read(editorSessionControllerProvider.notifier).clear();
    await _manager.close();
    await VaultStateStorage.saveLastVaultPath(null);
    state = state.copyWith(currentVault: () => null, isLoading: false);
  }
}

/// Riverpod provider for [VaultSessionController].
final vaultSessionControllerProvider =
    StateNotifierProvider<VaultSessionController, VaultSessionState>((ref) {
      return VaultSessionController(ref);
    });
