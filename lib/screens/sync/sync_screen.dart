import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/bloom_provider.dart';
import '../../services/sync_service.dart';
import '../../theme/bloom_theme.dart';

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
      final sync = context.read<BloomProvider>().syncService;
      if (sync.currentState == SyncState.disconnected) {
        sync.connect();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final sync = prov.syncService;
        final state = sync.currentState;
        final isLinked = sync.isPartnerLinked;
        final lastSynced = sync.lastSyncedAt;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Text(
                'Partner Sync',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 16),

              // Status Card
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        state == SyncState.connected || state == SyncState.success
                            ? Icons.cloud_done_rounded
                            : state == SyncState.syncing
                                ? Icons.sync_rounded
                                : state == SyncState.connecting
                                    ? Icons.cloud_sync_rounded
                                    : state == SyncState.waitingApproval
                                        ? Icons.notification_important_rounded
                                        : Icons.cloud_off_rounded,
                        size: 46,
                        color: state == SyncState.connected || state == SyncState.success
                            ? BloomColors.sage
                            : state == SyncState.syncing
                                ? BloomColors.rose500
                                : state == SyncState.waitingApproval
                                    ? BloomColors.predictedOrange
                                    : state == SyncState.error
                                        ? BloomColors.periodRed
                                        : BloomColors.muted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state == SyncState.connected
                            ? (isLinked ? 'Linked & Ready' : 'Relay Connected')
                            : state == SyncState.connecting
                                ? 'Connecting to Relay...'
                                : state == SyncState.syncing
                                    ? 'Encrypting & Syncing Data...'
                                    : state == SyncState.waitingApproval
                                        ? 'Incoming Sync Request'
                                        : state == SyncState.success
                                            ? 'Sync Completed!'
                                            : state == SyncState.error
                                                ? 'Connection Error'
                                                : 'Disconnected',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: BloomColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AES-256 encrypted peer-to-peer relay',
                        style: TextStyle(fontSize: 12, color: BloomColors.muted),
                      ),
                      if (state == SyncState.disconnected || state == SyncState.error) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => sync.connect(),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reconnect Relay'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Incoming Request Banner
              if (state == SyncState.waitingApproval) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BloomColors.peach.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BloomColors.peach.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync_problem_rounded, color: BloomColors.predictedOrange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Partner requested data sync',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: BloomColors.ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Do you want to share your encrypted cycle and note logs with your partner?',
                        style: TextStyle(fontSize: 12, color: BloomColors.inkLight),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => sync.denySync(sync.pendingRequestId ?? ''),
                            child: const Text('Deny'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => sync.approveSync(sync.pendingRequestId ?? ''),
                            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.sage),
                            child: const Text('Approve & Sync'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // My Pairing Code
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Pairing Code',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BloomColors.ink),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: BloomColors.muted),
                            tooltip: 'Generate new code',
                            onPressed: () async {
                              await sync.regeneratePairingCode();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Generated new pairing code')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: BloomColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BloomColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              sync.pairingCode,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 8,
                                color: BloomColors.rose500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20, color: BloomColors.rose500),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: sync.pairingCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pairing code copied to clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this 6-character code with your partner to link devices',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: BloomColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Connect to Partner / Linked Partner Section
              if (!isLinked)
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connect to Partner',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: BloomColors.ink),
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
                          child: ElevatedButton.icon(
                            onPressed: _codeCtrl.text.trim().length == 6
                                ? () async {
                                    final entered = _codeCtrl.text.trim().toUpperCase();
                                    if (entered == sync.pairingCode.toUpperCase()) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter your partner's 6-character code, not your own code.")),
                                      );
                                      return;
                                    }
                                    await sync.pairWith(entered);
                                    if (context.mounted) {
                                      FocusScope.of(context).unfocus();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Sent pair request to partner...')),
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
                  ),
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Connected Partner',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: BloomColors.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastSynced != null
                                      ? 'Last synced: ${DateFormat('MMM d, h:mm a').format(lastSynced)}'
                                      : 'Never synced',
                                  style: const TextStyle(fontSize: 12, color: BloomColors.muted),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: BloomColors.sage.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Linked',
                                style: TextStyle(
                                  color: BloomColors.sage,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: state == SyncState.syncing
                                ? null
                                : () {
                                    sync.requestSync();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Requesting sync with partner...')),
                                    );
                                  },
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: Text(state == SyncState.syncing ? 'Syncing...' : 'Sync Now'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmUnlink(context, sync),
                            icon: const Icon(Icons.link_off_rounded, size: 16, color: BloomColors.periodRed),
                            label: const Text('Unlink Partner', style: TextStyle(color: BloomColors.periodRed)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmUnlink(BuildContext context, SyncService sync) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Partner?'),
        content: const Text('You will stop syncing data with this partner device. You can pair again at any time.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.periodRed),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await sync.unlinkPartner();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner unlinked')),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }
}
