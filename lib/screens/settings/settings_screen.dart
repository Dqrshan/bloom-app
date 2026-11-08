import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/bloom_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';
import '../ai/bloom_ai_chat_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final p = BloomPalette.of(context);
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            BloomDesign.gutter,
            12,
            BloomDesign.gutter,
            24,
          ),
          children: [
            const BloomPageHeader(title: 'Settings'),
            const SizedBox(height: 16),

            // Identity
            BloomDesign.card(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BloomColors.rose400, BloomColors.rose600],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_florist,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bloom', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          'Private Couples’ Period Tracker • v1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Companion
            BloomDesign.groupLabel(context, 'BLOOM AI'),
            BloomGroup(
              children: [
                _SettingsRow(
                  icon: Icons.auto_awesome,
                  iconColor: p.notes,
                  title: 'Bloom AI Companion',
                  subtitle:
                      'Ask about your cycle, symptoms, mood, or partner support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BloomAIChatScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Data
            BloomDesign.groupLabel(context, 'DATA MANAGEMENT'),
            BloomGroup(
              children: [
                _SettingsRow(
                  icon: Icons.picture_as_pdf_outlined,
                  iconColor: p.period,
                  title: 'Export PDF Health Report',
                  subtitle:
                      'Generate and share a printable period & symptom summary',
                  onTap: () => _exportPdf(context, prov),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsRow(
                  icon: Icons.file_download_outlined,
                  iconColor: p.notes,
                  title: 'Export JSON Backup',
                  subtitle: 'Save raw cycles and notes to a backup file',
                  onTap: () => _exportToFile(context),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsRow(
                  icon: Icons.file_upload_outlined,
                  iconColor: p.fertile,
                  title: 'Restore from Backup',
                  subtitle: 'Import data from a backup file',
                  onTap: () => _importFromFile(context),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsRow(
                  icon: Icons.delete_outline_rounded,
                  iconColor: p.period,
                  title: 'Clear All Data',
                  subtitle:
                      'Permanently delete cycles and notes from this device',
                  onTap: () => _deleteAll(context),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Privacy
            BloomDesign.groupLabel(context, 'PRIVACY & SECURITY'),
            BloomGroup(
              children: [
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  iconColor: p.fertile,
                  title: 'Security & Encryption',
                  subtitle:
                      'AES-256 client-side encryption, 100% on-device storage',
                  onTap: () => _showSecurityDialog(context),
                ),
                const Divider(height: 1, indent: 60),
                _SettingsRow(
                  icon: Icons.hub_outlined,
                  iconColor: p.notes,
                  title: 'How Partner Sync Works',
                  subtitle:
                      'Zero-knowledge relay — your data is never stored on a server',
                  onTap: () => _showSyncHowItWorks(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static Future<void> _exportPdf(
    BuildContext context,
    BloomProvider prov,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating PDF Report...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await PdfExportService.sharePeriodReport(
        context,
        cycles: prov.cycles,
        notes: prov.notes,
        averageCycleLength: prov.averageCycleLength,
        averagePeriodLength: prov.averagePeriodLength,
        currentDay: prov.currentDay,
        isOnPeriod: prov.isOnPeriod,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('PDF generation failed: $e')),
      );
    }
  }

  static Future<void> _exportToFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prov = context.read<BloomProvider>();
      final data = await prov.exportData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(json));

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Bloom Backup',
        fileName: 'bloom_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (path != null) {
        final file = File(path);
        if (!await file.exists() || await file.length() == 0) {
          await file.writeAsBytes(bytes);
        }
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup saved successfully!')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  static Future<void> _importFromFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<BloomProvider>();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.first;
      String jsonString;
      if (pickedFile.bytes != null) {
        jsonString = utf8.decode(pickedFile.bytes!);
      } else if (pickedFile.path != null) {
        jsonString = await File(pickedFile.path!).readAsString();
      } else {
        throw Exception('Could not read selected file');
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      await prov.importData(json);

      messenger.showSnackBar(
        const SnackBar(content: Text('Data imported successfully!')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  static Future<void> _deleteAll(BuildContext context) async {
    final prov = context.read<BloomProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: BloomPalette.of(ctx).period,
          size: 34,
        ),
        title: const Text('Delete everything?'),
        content: const Text(
          'All cycles, notes, and records will be permanently removed from this device. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: BloomPalette.of(ctx).period,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await prov.deleteAllData();
      messenger.showSnackBar(const SnackBar(content: Text('All data deleted')));
    }
  }

  static void _showSecurityDialog(BuildContext context) {
    final p = BloomPalette.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield, color: p.fertile),
            const SizedBox(width: 8),
            const Text('Security & Privacy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Device-Local Storage',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'All personal health data is stored strictly on your device storage. No centralized database or cloud account exists.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                '2. Client-Side Encryption',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Data is encrypted using AES-256 before leaving your phone during partner sync.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                '3. Zero-Knowledge Relay',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'The relay server is stateless and never logs or stores any plaintext data.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showSyncHowItWorks(BuildContext context) {
    final p = BloomPalette.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.hub_outlined, color: p.period),
            const SizedBox(width: 8),
            const Text('How Sync Works'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step 1: Pairing',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Enter your partner’s 6-character pairing code to establish a secure peer link.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                'Step 2: Mutual Approval',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Whenever a sync is initiated, the other device is prompted to explicitly approve data transfer.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                'Step 3: Encrypted Exchange',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Cycles and notes are encrypted locally, forwarded through the relay server, and merged cleanly on your partner’s phone.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(BloomDesign.radiusSm),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}
