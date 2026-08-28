import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/bloom_provider.dart';
import '../../services/pdf_export_service.dart';
import '../../theme/bloom_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 20),

              // App Header Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BloomColors.divider, width: 0.5),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [BloomColors.rose500, BloomColors.rose600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_florist, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bloom',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Private Couples’ Period Tracker • v1.0.0',
                      style: TextStyle(color: BloomColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data Management Section
              _header('DATA MANAGEMENT'),
              _section([
                _item(
                  Icons.picture_as_pdf_outlined,
                  'Export PDF Health Report',
                  'Generate and share a printable period & symptom summary',
                  onTap: () => _exportPdf(context, prov),
                ),
                const Divider(height: 1, indent: 52),
                _item(
                  Icons.file_download_outlined,
                  'Export JSON Backup',
                  'Save raw cycles and notes to a backup file',
                  onTap: () => _exportToFile(context),
                ),
                const Divider(height: 1, indent: 52),
                _item(
                  Icons.file_upload_outlined,
                  'Restore from Backup',
                  'Import data from a backup file',
                  onTap: () => _importFromFile(context),
                ),
                const Divider(height: 1, indent: 52),
                _item(
                  Icons.delete_outline_rounded,
                  'Clear All Data',
                  'Permanently delete cycles and notes from this device',
                  color: BloomColors.periodRed,
                  onTap: () => _deleteAll(context),
                ),
              ]),
              const SizedBox(height: 24),

              // Privacy & Security Section
              _header('PRIVACY & SECURITY'),
              _section([
                _item(
                  Icons.shield_outlined,
                  'Security & Encryption',
                  'AES-256 client-side encryption, 100% on-device storage',
                  onTap: () => _showSecurityDialog(context),
                ),
                const Divider(height: 1, indent: 52),
                _item(
                  Icons.hub_outlined,
                  'How Partner Sync Works',
                  'Zero-knowledge relay — your data is never stored on a server',
                  onTap: () => _showSyncHowItWorks(context),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  static Widget _header(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: BloomColors.muted,
            letterSpacing: 0.8,
          ),
        ),
      );

  static Widget _section(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BloomColors.divider, width: 0.5),
      ),
      child: Column(children: children),
    );
  }

  static Widget _item(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? BloomColors.inkLight, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: color ?? BloomColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: BloomColors.muted),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 18, color: BloomColors.muted)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  static Future<void> _exportPdf(BuildContext context, BloomProvider prov) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Generating PDF Report...'), duration: Duration(seconds: 1)),
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
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
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
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  static Future<void> _deleteAll(BuildContext context) async {
    final prov = context.read<BloomProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_amber_rounded, color: BloomColors.periodRed, size: 36),
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
            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.periodRed),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await prov.deleteAllData();
      messenger.showSnackBar(
        const SnackBar(content: Text('All data deleted')),
      );
    }
  }

  static void _showSecurityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: BloomColors.sage),
            SizedBox(width: 8),
            Text('Security & Privacy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Device-Local Storage',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'All personal health data is stored strictly on your device storage. No centralized database or cloud account exists.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
              ),
              SizedBox(height: 12),
              Text(
                '2. Client-Side Encryption',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Data is encrypted using AES-256 before leaving your phone during partner sync.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
              ),
              SizedBox(height: 12),
              Text(
                '3. Zero-Knowledge Relay',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'The relay server is stateless and never logs or stores any plaintext data.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.hub_outlined, color: BloomColors.rose500),
            SizedBox(width: 8),
            Text('How Sync Works'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Step 1: Pairing',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Enter your partner’s 6-character pairing code to establish a secure peer link.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
              ),
              SizedBox(height: 12),
              Text(
                'Step 2: Mutual Approval',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Whenever a sync is initiated, the other device is prompted to explicitly approve data transfer.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
              ),
              SizedBox(height: 12),
              Text(
                'Step 3: Encrypted Exchange',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Cycles and notes are encrypted locally, forwarded through the relay server, and merged cleanly on your partner’s phone.',
                style: TextStyle(fontSize: 13, color: BloomColors.inkLight),
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
