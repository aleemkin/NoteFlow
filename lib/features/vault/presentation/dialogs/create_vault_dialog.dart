import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:noteflow/core/theme/app_theme.dart';
import 'package:noteflow/core/platform/app_platform.dart';
import 'package:path/path.dart' as p;

/// Modal dialog that guides the user through creating a new local-first vault.
class CreateVaultDialog extends StatefulWidget {
  const CreateVaultDialog({super.key});

  @override
  State<CreateVaultDialog> createState() => _CreateVaultDialogState();
}

class _CreateVaultDialogState extends State<CreateVaultDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  bool _initWelcomeNotes = true;
  String? _errorMessage;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'My Vault');
    _locationController = TextEditingController(
      text: AppPlatform.getDeviceDocumentsDirectorySync(),
    );
    _initDeviceDirectory();
  }

  Future<void> _initDeviceDirectory() async {
    final docsPath = await AppPlatform.getDeviceDocumentsDirectory();
    if (mounted &&
        (_locationController.text.isEmpty ||
            _locationController.text != docsPath)) {
      setState(() {
        _locationController.text = docsPath;
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
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Vault Parent Folder',
        initialDirectory: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
      );
      if (selected != null && mounted) {
        setState(() {
          _locationController.text = selected;
          _errorMessage = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (_isCreating) return;

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vault name cannot be empty');
      return;
    }

    if (name.contains(RegExp(r'[\\/:*?"<>|]'))) {
      setState(() => _errorMessage = 'Vault name contains invalid characters');
      return;
    }

    if (location.isEmpty) {
      setState(() => _errorMessage = 'Location cannot be empty');
      return;
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
    final previewPath = p.join(
      _locationController.text.trim(),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: Icon(
                Icons.create_new_folder_outlined,
                color: Color(0xFF58A6FF),
                size: 20,
              ),
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
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFFDFE2EB),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. My Vault',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6E7681),
                  ),
                  prefixIcon: const Icon(
                    Icons.folder_outlined,
                    size: 17,
                    color: Color(0xFF8B949E),
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
              const Text(
                'LOCATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B949E),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Color(0xFFDFE2EB),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Parent directory path',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6E7681),
                        ),
                        prefixIcon: const Icon(
                          Icons.folder_open_outlined,
                          size: 17,
                          color: Color(0xFF8B949E),
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
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _isCreating ? null : _pickLocation,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
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
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFF8B949E),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Will be created at: $previewPath',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF8B949E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _initWelcomeNotes,
                    activeColor: const Color(0xFF0C6FFF),
                    checkColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF484F58)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: _isCreating
                        ? null
                        : (val) =>
                              setState(() => _initWelcomeNotes = val ?? true),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Initialize with starter welcome note',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFDFE2EB),
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF8B949E)),
          ),
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
              : const Icon(Icons.check_rounded, size: 16),
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
