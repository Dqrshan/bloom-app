import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/bloom_provider.dart';
import '../../services/sync_service.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-connect to relay server when opening sync screen if disconnected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sync = context.read<BloomProvider>().syncService;
      if (sync.currentState == SyncState.disconnected) {
        sync.connect();
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final sync = prov.syncService;
        final state = sync.currentState;
        final isLinked = sync.isPartnerLinked;
        final lastSynced = sync.lastSyncedAt;

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
            const BloomPageHeader(
              title: 'Partner Sync',
              subtitle: 'AES-256 encrypted peer-to-peer relay',
            ),
            const SizedBox(height: 16),

            // Relay status
            BloomDesign.card(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _statusColor(state, p).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(state),
                      size: 34,
                      color: _statusColor(state, p),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _statusLabel(state, isLinked),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (state == SyncState.disconnected ||
                      state == SyncState.error) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => sync.connect(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reconnect Relay'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Incoming request
            if (state == SyncState.waitingApproval) ...[
              BloomDesign.card(
                color: p.predictedContainer,
                borderColor: p.predicted.withValues(alpha: 0.4),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.sync_problem_rounded, color: p.predicted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Partner requested data sync',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Do you want to share your encrypted cycle and note logs with your partner?',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              sync.denySync(sync.pendingRequestId ?? ''),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Deny'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () =>
                              sync.approveSync(sync.pendingRequestId ?? ''),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.fertile,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Approve & Sync'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // My pairing code
            BloomDesign.card(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Pairing Code',
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: p.muted,
                        ),
                        tooltip: 'Generate new code',
                        onPressed: () async {
                          await sync.regeneratePairingCode();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Generated new pairing code'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
                      border: Border.all(color: p.divider, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              sync.pairingCode,
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    fontVariations: const [
                                      FontVariation('wght', 700),
                                    ],
                                    letterSpacing: 7,
                                    color: p.period,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 19,
                            color: p.period,
                          ),
                          tooltip: 'Copy Code',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: sync.pairingCode),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pairing code copied to clipboard',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Share this 6-character code with your partner to link devices',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: p.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Partner
            if (!isLinked)
              BloomDesign.card(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect to Partner',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        hintText: "Enter partner's 6-character code",
                        counterText: '',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _codeCtrl.text.trim().length == 6
                            ? () async {
                                final entered = _codeCtrl.text
                                    .trim()
                                    .toUpperCase();
                                if (entered == sync.pairingCode.toUpperCase()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter your partner's 6-character code, not your own code.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await sync.pairWith(entered);
                                if (context.mounted) {
                                  FocusScope.of(context).unfocus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sent pair request to partner...',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Connect with Partner'),
                      ),
                    ),
                  ],
                ),
              )
            else
              BloomDesign.card(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connected Partner',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lastSynced != null
                                    ? 'Last synced: ${DateFormat('MMM d, h:mm a').format(lastSynced)}'
                                    : 'Never synced',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: p.fertileContainer,
                            borderRadius: BorderRadius.circular(
                              BloomDesign.radiusPill,
                            ),
                          ),
                          child: Text(
                            'Linked',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontVariations: const [
                                    FontVariation('wght', 600),
                                  ],
                                  color: p.fertile,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: state == SyncState.syncing
                            ? null
                            : () {
                                sync.requestSync();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Requesting sync with partner...',
                                    ),
                                  ),
                                );
                              },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          state == SyncState.syncing
                              ? 'Syncing...'
                              : 'Sync Now',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmUnlink(context, sync),
                        icon: const Icon(Icons.link_off_rounded, size: 16),
                        label: Text(
                          'Unlink Partner',
                          style: TextStyle(color: p.period),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: p.period.withValues(alpha: 0.4),
                          ),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              BloomDesign.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static IconData _statusIcon(SyncState state) {
    if (state == SyncState.connected || state == SyncState.success) {
      return Icons.cloud_done_rounded;
    }
    if (state == SyncState.syncing) return Icons.sync_rounded;
    if (state == SyncState.connecting) return Icons.cloud_sync_rounded;
    if (state == SyncState.waitingApproval) {
      return Icons.notification_important_rounded;
    }
    if (state == SyncState.error) return Icons.cloud_off_rounded;
    return Icons.cloud_off_rounded;
  }

  static Color _statusColor(SyncState state, BloomPalette p) {
    if (state == SyncState.connected || state == SyncState.success) {
      return p.fertile;
    }
    if (state == SyncState.syncing) return p.period;
    if (state == SyncState.waitingApproval) return p.predicted;
    if (state == SyncState.error) return p.period;
    return p.muted;
  }

  static String _statusLabel(SyncState state, bool isLinked) {
    switch (state) {
      case SyncState.connected:
        return isLinked ? 'Linked & Ready' : 'Relay Connected';
      case SyncState.connecting:
        return 'Connecting to Relay...';
      case SyncState.syncing:
        return 'Encrypting & Syncing Data...';
      case SyncState.waitingApproval:
        return 'Incoming Sync Request';
      case SyncState.success:
        return 'Sync Completed!';
      case SyncState.error:
        return 'Connection Error';
      case SyncState.disconnected:
        return 'Disconnected';
    }
  }

  Future<void> _confirmUnlink(BuildContext context, SyncService sync) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Partner?'),
        content: const Text(
          'You will stop syncing data with this partner device. You can pair again at any time.',
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
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sync.unlinkPartner();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Partner unlinked')));
      }
    }
  }
}
