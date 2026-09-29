import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:noteflow/core/widgets/app_svg_icon.dart';
import 'package:path/path.dart' as p;

/// Modal dialog that guides the user through creating a new local-first vault.
class CreateVaultDialog extends StatefulWidget {
  const CreateVaultDialog({super.key});

  /// Formats an absolute filesystem path into a human-friendly display path,
  /// eliminating Android/emulator storage noise (e.g. `/storage/emulated/0`,
  /// `emulator/0/`, `/data/user/0/...`) and replacing user home with `~`.
  static String formatDisplayLocation(String fullPath) {
    if (fullPath.trim().isEmpty) return '';

    var path = fullPath.replaceAll(r'\', '/');
    while (path.endsWith('/') && path.length > 1) {
      path = path.substring(0, path.length - 1);
    }

    // Android primary shared storage patterns:
    // e.g. /storage/emulated/0, /storage/emulator/0, emulator/0, emulated/0, /storage/self/primary, /sdcard
    final androidPrefixRegex = RegExp(
      r'^(?:/?storage/)?(?:emulated|emulator)/\d+/?|^/?(?:emulated|emulator)/\d+/?|^/storage/self/primary/?|^/sdcard/?',
      caseSensitive: false,
    );

    if (androidPrefixRegex.hasMatch(path)) {
      final stripped = path.replaceFirst(androidPrefixRegex, '');
      final segments = stripped.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) {
        return 'Internal Storage';
      }
      return segments.join(' / ');
    }

    // Android app-private storage: /data/user/0/<pkg>/... or /data/data/<pkg>/...
    final appDataMatch = RegExp(
      r'^/data/(?:user/\d+|data)/[^/]+/(?:app_flutter/)?(.*)$',
    ).firstMatch(path);
    if (appDataMatch != null) {
      final sub = appDataMatch.group(1);
      if (sub == null || sub.isEmpty) return 'App Storage';
      final segments = sub.split('/').where((s) => s.isNotEmpty).toList();
      return segments.isEmpty
          ? 'App Storage'
          : 'App Storage / ${segments.join(' / ')}';
    }

    // iOS container sandbox
    final iosMatch = RegExp(
      r'^/var/mobile/Containers/Data/Application/[^/]+/Documents/?(.*)$',
    ).firstMatch(path);
    if (iosMatch != null) {
      final sub = iosMatch.group(1);
      if (sub == null || sub.isEmpty) return 'Documents';
      final segments = sub.split('/').where((s) => s.isNotEmpty).toList();
      return segments.isEmpty
          ? 'Documents'
          : 'Documents / ${segments.join(' / ')}';
    }

    // User home directory (Linux/macOS/Windows)
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      final normalizedHome = home.replaceAll(r'\', '/');
      if (path == normalizedHome) {
        return '~';
      }
      if (path.startsWith('$normalizedHome/')) {
        return '~/${path.substring(normalizedHome.length + 1)}';
      }
    }

    return path;
  }

  /// Formats the preview location breadcrumb displayed to the user.
  static String formatPreviewPath(String location, String name) {
    final cleanName = name.trim();
    final cleanLocation = formatDisplayLocation(location);

    if (cleanLocation.isEmpty && cleanName.isEmpty) {
      return 'My Vault';
    }
    if (cleanLocation.isEmpty) {
      return cleanName;
    }
    if (cleanName.isEmpty) {
      return cleanLocation;
    }

    return '$cleanLocation / $cleanName';
  }

  @override
  State<CreateVaultDialog> createState() => _CreateVaultDialogState();
}

class _CreateVaultDialogState extends State<CreateVaultDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late String _rawLocationPath;
  late String _defaultDocsPath;
  bool _userManuallyEditedLocation = false;
  bool _initWelcomeNotes = true;
  String? _errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'My Vault');
    _rawLocationPath = AppPlatform.getDeviceDocumentsDirectorySync();
    _defaultDocsPath = _rawLocationPath;
    _locationController = TextEditingController(
      text: CreateVaultDialog.formatDisplayLocation(_rawLocationPath),
    );
    _initDeviceDirectory();
  }

  Future<void> _initDeviceDirectory() async {
    final docsPath = await AppPlatform.getDeviceDocumentsDirectory();
    if (mounted && !_userManuallyEditedLocation) {
      setState(() {
        _defaultDocsPath = docsPath;
        _rawLocationPath = docsPath;
        _locationController.text = CreateVaultDialog.formatDisplayLocation(
          docsPath,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    try {
      final initialDir =
          _rawLocationPath.trim().isNotEmpty &&
              Directory(_rawLocationPath.trim()).existsSync()
          ? _rawLocationPath.trim()
          : null;

      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Vault Parent Folder',
        initialDirectory: initialDir,
      );
      if (selected != null && mounted) {
        setState(() {
          _rawLocationPath = selected;
          _userManuallyEditedLocation = false;
          _locationController.text = CreateVaultDialog.formatDisplayLocation(
            selected,
          );
          _errorMessage = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_isCreating) return;

    final name = _nameController.text.trim();
    final displayedText = _locationController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vault name cannot be empty');
      return;
    }

    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) {
      setState(() => _errorMessage = 'Vault name contains invalid characters');
      return;
    }

    if (displayedText.isEmpty) {
      setState(() => _errorMessage = 'Location cannot be empty');
      return;
    }

    // Determine the actual filesystem location path.
    // If user edited the textfield to a custom path that differs from the
    // formatted display path of _rawLocationPath, respect their typed input.
    String location = _rawLocationPath.trim();
    if (_userManuallyEditedLocation &&
        displayedText !=
            CreateVaultDialog.formatDisplayLocation(_rawLocationPath)) {
      location = displayedText;
    }

    // Expand ~ home shortcut if present
    if (location.startsWith('~')) {
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        if (location == '~') {
          location = home;
        } else if (location.startsWith('~/') || location.startsWith(r'~\')) {
          location = p.join(home, location.substring(2));
        }
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final parentDir = Directory(location);
      if (!await parentDir.exists()) {
        try {
          await parentDir.create(recursive: true);
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Unable to create parent directory: $e';
              _isCreating = false;
            });
          }
          return;
        }
      }

      final vaultPath = p.join(location, name);
      final vaultDir = Directory(vaultPath);

      if (await vaultDir.exists()) {
        try {
          final entries = await vaultDir.list().toList();
          if (entries.isNotEmpty) {
            if (mounted) {
              setState(() {
                _errorMessage =
                    'Folder "$name" already exists at this location and is not empty';
                _isCreating = false;
              });
            }
            return;
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Cannot access folder: $e';
              _isCreating = false;
            });
          }
          return;
        }
      } else {
        try {
          await vaultDir.create(recursive: true);
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Unable to create vault folder: $e';
              _isCreating = false;
            });
          }
          return;
        }
      }

      if (_initWelcomeNotes) {
        try {
          final welcomeFile = File(p.join(vaultPath, 'Welcome.md'));
          if (!await welcomeFile.exists()) {
            await welcomeFile.writeAsString('''# Welcome to $name

This is your new local-first workspace in **Noteflow**.

## Quick Tips
- Create notes and drawings with the sidebar controls or `Ctrl+N`.
- Add Excalidraw vector canvases with `@@drawing ./diagram.excalidraw`.
- Organize your thoughts with Markdown headings, lists, and tags (`@@imp`, `@@info`, `@@tag`).
''');
          }
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context, vaultPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error creating vault: $e';
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLocation =
        (_userManuallyEditedLocation &&
            _locationController.text.trim() !=
                CreateVaultDialog.formatDisplayLocation(_rawLocationPath))
        ? _locationController.text.trim()
        : _rawLocationPath;
    final previewDisplay = CreateVaultDialog.formatPreviewPath(
      effectiveLocation,
      _nameController.text.trim(),
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF58A6FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF58A6FF).withValues(alpha: 0.25),
              ),
            ),
            child: const Center(
              child: AppSvgIcon.vault(size: 20, color: Color(0xFF58A6FF)),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Vault',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDFE2EB),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Initialize a local-first markdown workspace',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF8B949E)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VAULT NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B949E),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFDFE2EB),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. My Vault',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E7681),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: AppSvgIcon.vault(size: 16, color: Color(0xFF8B949E)),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF30363D)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF58A6FF),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B949E),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  if (_rawLocationPath != _defaultDocsPath &&
                      _defaultDocsPath.isNotEmpty)
                    InkWell(
                      onTap: _isCreating
                          ? null
                          : () {
                              setState(() {
                                _rawLocationPath = _defaultDocsPath;
                                _userManuallyEditedLocation = false;
                                _locationController.text =
                                    CreateVaultDialog.formatDisplayLocation(
                                      _defaultDocsPath,
                                    );
                                _errorMessage = null;
                              });
                            },
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'Reset to default',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF58A6FF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFDFE2EB),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Parent directory folder',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7681),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(12),
                          child: AppSvgIcon.openFolder(
                            size: 16,
                            color: Color(0xFF8B949E),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0D1117),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF30363D),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF30363D),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF58A6FF),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _errorMessage = null;
                          _userManuallyEditedLocation = true;
                          _rawLocationPath = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isCreating ? null : _pickLocation,
                    icon: const AppSvgIcon.openFolder(
                      size: 16,
                      color: Color(0xFFDFE2EB),
                    ),
                    label: const Text('Browse...'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDFE2EB),
                      side: const BorderSide(color: Color(0xFF30363D)),
                      backgroundColor: const Color(0xFF0D1117),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon.folder(size: 15, color: Color(0xFF58A6FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Will be created at: ',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF8B949E),
                          ),
                          children: [
                            TextSpan(
                              text: previewDisplay,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDFE2EB),
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _isCreating
                    ? null
                    : () => setState(
                        () => _initWelcomeNotes = !_initWelcomeNotes,
                      ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 2,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _initWelcomeNotes,
                          activeColor: const Color(0xFF0C6FFF),
                          checkColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF484F58)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: _isCreating
                              ? null
                              : (val) => setState(
                                  () => _initWelcomeNotes = val ?? true,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppSvgIcon.notes(
                        size: 16,
                        color: _initWelcomeNotes
                            ? const Color(0xFF58A6FF)
                            : const Color(0xFF8B949E),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Initialize with starter welcome note',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFDFE2EB),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Includes Markdown guide and quick tips',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6E7681),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x1EF85149),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x44F85149)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: Color(0xFFF85149),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFF85149),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8B949E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isCreating ? null : _submit,
          icon: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const AppSvgIcon.newFolder(size: 16, color: Colors.white),
          label: Text(_isCreating ? 'Creating...' : 'Create Vault'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0C6FFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
