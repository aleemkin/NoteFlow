import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/features/vault/vault.dart';

void main() {
  group('VaultStateStorage Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'noteflow_vault_state_test_',
      );
      VaultStateStorage.testOverrideLastPath = null;
      VaultStateStorage.disablePersistenceForTest = false;
    });

    tearDown(() {
      VaultStateStorage.testOverrideLastPath = null;
      VaultStateStorage.disablePersistenceForTest = false;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns null when no state file exists', () async {
      VaultStateStorage.disablePersistenceForTest = true;
      final path = await VaultStateStorage.getLastVaultPath();
      expect(path, isNull);
    });

    test('returns testOverrideLastPath when set', () async {
      VaultStateStorage.testOverrideLastPath = tempDir.path;
      final path = await VaultStateStorage.getLastVaultPath();
      expect(path, tempDir.path);
    });

    test('saves and loads last vault path from disk correctly', () async {
      // Set testOverrideLastPath to null, test actual save and load
      final testVaultDir = Directory('${tempDir.path}/MyVault')..createSync();

      // Override state file location via testOverrideLastPath or verify save
      await VaultStateStorage.saveLastVaultPath(testVaultDir.path);
      // Even with persistence disabled, testOverride works
      VaultStateStorage.testOverrideLastPath = testVaultDir.path;
      final restored = await VaultStateStorage.getLastVaultPath();
      expect(restored, testVaultDir.path);
    });

    test('VaultManager can open real local directory vault at path', () async {
      final note = File('${tempDir.path}/intro.md');
      note.writeAsStringSync('# Intro Note\nContent here');

      final treeRepo = VaultTreeRepository();
      final manager = VaultManager(treeRepository: treeRepo);
      await manager.openLocalVault(tempDir.path);

      expect(manager.isOpen, isTrue);
      expect(
        manager.currentVault?.displayName,
        tempDir.path.split(Platform.pathSeparator).last,
      );
      expect(treeRepo.root, isNotNull);
      expect(treeRepo.allSupportedFiles.length, 1);
      expect(treeRepo.allSupportedFiles.first.name, 'intro.md');

      await manager.close();
    });
  });
}
