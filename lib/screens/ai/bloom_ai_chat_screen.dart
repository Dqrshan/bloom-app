import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chat_message.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';

class BloomAIChatScreen extends StatefulWidget {
  const BloomAIChatScreen({super.key});

  @override
  State<BloomAIChatScreen> createState() => _BloomAIChatScreenState();
}

class _BloomAIChatScreenState extends State<BloomAIChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  static const _quickPrompts = [
    '🌸 What foods are best for my current phase?',
    '✨ Natural remedies for menstrual cramps',
    '💫 How can my partner support me during PMS?',
    '🌿 Gentle movement and yoga for period days',
  ];

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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final conv = prov.currentConversation;
        final messages = conv?.messages ?? [];
        final isSending = prov.isChatSending;

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
                    children: [
                      const Text(
                        'Bloom AI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        conv?.title ?? 'Cycle & Wellness Guide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: BloomColors.muted, fontWeight: FontWeight.w500),
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
                onPressed: () => _openHistorySheet(context, prov),
              ),
              IconButton(
                icon: const Icon(Icons.add_comment_outlined, color: BloomColors.rose500),
                tooltip: 'New Chat',
                onPressed: () async {
                  await prov.createConversation();
                  _scrollToBottom();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Message List
              Expanded(
                child: messages.isEmpty
                    ? _buildEmptyState(context, prov)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: messages.length + (isSending ? 1 : 0),
                        itemBuilder: (ctx, idx) {
                          if (idx == messages.length && isSending) {
                            return _buildTypingIndicator();
                          }
                          final msg = messages[idx];
                          return _buildMessageBubble(context, prov, conv!, msg);
                        },
                      ),
              ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: BloomColors.divider, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: BloomColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: BloomColors.divider),
                          ),
                          child: TextField(
                            controller: _inputCtrl,
                            focusNode: _focusNode,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Ask Bloom AI anything...',
                              hintStyle: TextStyle(fontSize: 13, color: BloomColors.muted),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(prov),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: BloomColors.rose500,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                          onPressed: isSending ? null : () => _sendMessage(prov),
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

  Widget _buildEmptyState(BuildContext context, BloomProvider prov) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BloomColors.rose500, BloomColors.rose600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'How can Bloom AI help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: BloomColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask about fertility, phase-based nutrition, natural cramp relief, or hormone rhythms.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: BloomColors.muted),
            ),
            const SizedBox(height: 24),
            ..._quickPrompts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      _inputCtrl.text = p.substring(2).trim();
                      _sendMessage(prov);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BloomColors.divider),
                      ),
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: BloomColors.ink,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    BloomProvider prov,
    ChatConversation conv,
    ChatMessage msg,
  ) {
    final isUser = msg.isUser;
    final timeStr = DateFormat('h:mm a').format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                color: BloomColors.rose500.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 15),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context, prov, conv, msg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? BloomColors.rose500 : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser ? null : Border.all(color: BloomColors.divider, width: 0.5),
                  boxShadow: isUser
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (isUser)
                      Text(
                        msg.text,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      )
                    else
                      MarkdownBody(
                        data: msg.text,
                        selectable: false,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14, color: BloomColors.ink, height: 1.45),
                          strong: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: BloomColors.ink),
                          em: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: BloomColors.ink),
                          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BloomColors.ink),
                          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: BloomColors.ink),
                          h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BloomColors.ink),
                          listBullet: const TextStyle(fontSize: 14, color: BloomColors.rose500, fontWeight: FontWeight.bold),
                          blockquote: const TextStyle(fontSize: 13, color: BloomColors.inkLight),
                          code: const TextStyle(fontSize: 12, backgroundColor: BloomColors.surfaceAlt, color: BloomColors.ink),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white.withValues(alpha: 0.7) : BloomColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: BloomColors.rose500.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: BloomColors.rose500, size: 15),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BloomColors.divider, width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: BloomColors.rose500),
                ),
                SizedBox(width: 8),
                Text(
                  'Bloom AI is thinking...',
                  style: TextStyle(fontSize: 12, color: BloomColors.muted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    BloomProvider prov,
    ChatConversation conv,
    ChatMessage msg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Message Text'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied to clipboard')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: BloomColors.periodRed),
              title: const Text('Delete Message', style: TextStyle(color: BloomColors.periodRed)),
              onTap: () async {
                Navigator.pop(ctx);
                await prov.deleteChatMessage(conv.id, msg.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openHistorySheet(BuildContext context, BloomProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<BloomProvider>(
        builder: (ctx, p, _) {
          final list = p.conversations;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chat History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    if (list.isNotEmpty)
                      TextButton(
                        onPressed: () => _confirmClearAll(context, p),
                        child: const Text('Clear All', style: TextStyle(color: BloomColors.periodRed, fontSize: 13)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text('No previous conversations found.', style: TextStyle(color: BloomColors.muted)),
                        )
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (ctx, index) => const Divider(height: 1),
                          itemBuilder: (_, idx) {
                            final c = list[idx];
                            final isSelected = p.currentConversation?.id == c.id;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? BloomColors.rose500.withValues(alpha: 0.15)
                                      : BloomColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: isSelected ? BloomColors.rose500 : BloomColors.inkLight,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? BloomColors.rose500 : BloomColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                '${c.messages.length} messages • ${DateFormat('MMM d, yyyy').format(c.updatedAt)}',
                                style: const TextStyle(fontSize: 11, color: BloomColors.muted),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16, color: BloomColors.muted),
                                    tooltip: 'Rename',
                                    onPressed: () => _showRenameDialog(context, p, c),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: BloomColors.periodRed),
                                    tooltip: 'Delete',
                                    onPressed: () => p.deleteConversation(c.id),
                                  ),
                                ],
                              ),
                              onTap: () {
                                p.selectConversation(c.id);
                                Navigator.pop(ctx);
                                _scrollToBottom();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, BloomProvider prov, ChatConversation conv) {
    final ctrl = TextEditingController(text: conv.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter new title...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                prov.renameConversation(conv.id, text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, BloomProvider prov) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all chat history?'),
        content: const Text('All saved Bloom AI conversations will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              prov.clearAllConversations();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: BloomColors.periodRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BloomProvider prov) {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    prov.sendChatMessage(text);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
