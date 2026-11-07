import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';

class BloomAIChatScreen extends StatefulWidget {
  const BloomAIChatScreen({super.key});
  @override State<BloomAIChatScreen> createState() => _BloomAIChatScreenState();
}

class _BloomAIChatScreenState extends State<BloomAIChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<BloomProvider>();
      if (prov.conversations.isNotEmpty && prov.currentConversation == null) {
        prov.selectConversation(prov.conversations.first.id);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: BloomColors.rose500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Bloom AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Cycle & Wellness Guide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: BloomColors.muted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: BloomColors.ink),
                tooltip: 'Chat History',
                onPressed: () {},
              ),
            ],
          ),
          body: Center(
            child: Text(
              'Bloom AI Chat Screen',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }
}
