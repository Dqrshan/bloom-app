import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../services/bloom_provider.dart';
import '../../theme/bloom_theme.dart';
import '../../theme/design_system.dart';

class BloomAIChatScreen extends StatefulWidget {
  const BloomAIChatScreen({super.key});

  @override
  State<BloomAIChatScreen> createState() => _BloomAIChatScreenState();
}

class _BloomAIChatScreenState extends State<BloomAIChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  int _messageCount = 0;

  static const _suggestions = [
    'How should I prepare for my period?',
    'What causes cramps and how do I ease them?',
    'How can I support my partner this week?',
    'What foods help during the luteal phase?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<BloomProvider>();
      if (prov.conversations.isNotEmpty && prov.currentConversation == null) {
        prov.selectConversation(prov.conversations.first.id);
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final prov = context.read<BloomProvider>();
    await prov.sendChatMessage(text);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BloomProvider>(
      builder: (context, prov, _) {
        final p = BloomPalette.of(context);
        final theme = Theme.of(context);
        final conversation = prov.currentConversation;
        final messages = conversation?.messages ?? const <ChatMessage>[];

        if (messages.length != _messageCount) {
          _messageCount = messages.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToLatest(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: p.notesContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(Icons.auto_awesome, color: p.notes, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bloom AI', style: theme.textTheme.titleMedium),
                      Text(
                        'Cycle & Wellness Guide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: p.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.history_rounded, color: p.ink),
                tooltip: 'Chat History',
                onPressed: () => _openHistory(context, prov),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _EmptyThread(
                        suggestions: _suggestions,
                        onSuggestion: (s) {
                          _inputCtrl.text = s;
                          _inputCtrl.selection = TextSelection.collapsed(
                            offset: s.length,
                          );
                          _send();
                        },
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(
                          BloomDesign.gutter,
                          16,
                          BloomDesign.gutter,
                          16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, i) => _MessageBubble(
                          message: messages[i],
                          onDelete: () =>
                              _confirmDeleteMessage(context, prov, messages[i]),
                        ),
                      ),
              ),
              _Composer(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                sending: prov.isChatSending,
                onSend: _send,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteMessage(
    BuildContext context,
    BloomProvider prov,
    ChatMessage message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'This message will be removed from this conversation.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && prov.currentConversation != null) {
      await prov.deleteChatMessage(prov.currentConversation!.id, message.id);
    }
  }

  void _openHistory(BuildContext context, BloomProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _HistorySheet(
        conversations: prov.conversations,
        currentId: prov.currentConversation?.id,
        onSelect: (id) async {
          Navigator.pop(ctx);
          await prov.selectConversation(id);
        },
        onCreate: () async {
          Navigator.pop(ctx);
          await prov.createConversation();
        },
        onRename: (id, currentTitle) async {
          final title = await _promptForTitle(ctx, currentTitle);
          if (title != null) {
            await prov.renameConversation(id, title);
          }
        },
        onDelete: (id) async {
          final confirmed = await showDialog<bool>(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: const Text('Delete conversation?'),
              content: const Text(
                'This conversation and all of its messages will be permanently removed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BloomPalette.of(dctx).period,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await prov.deleteConversation(id);
          }
        },
      ),
    );
  }

  Future<String?> _promptForTitle(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Conversation title'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onDelete;

  const _MessageBubble({required this.message, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: onDelete,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: p.period,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: p.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.notesContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.auto_awesome, size: 15, color: p.notes),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onLongPress: onDelete,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.divider, width: 1),
                    ),
                    child: MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: _markdownSheet(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: p.muted,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownSheet(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium!.copyWith(
      color: p.inkLight,
      height: 1.5,
    );
    final strong = theme.textTheme.titleSmall!.copyWith(color: p.ink);
    return MarkdownStyleSheet(
      p: body,
      h1: strong,
      h2: strong,
      h3: strong,
      h1Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h2Padding: const EdgeInsets.only(top: 8, bottom: 4),
      h3Padding: const EdgeInsets.only(top: 6, bottom: 2),
      listBullet: body,
      blockquote: body.copyWith(color: p.muted),
      blockquotePadding: const EdgeInsets.only(left: 12),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: p.notes, width: 3)),
      ),
      code: body.copyWith(fontSize: 13, backgroundColor: p.surfaceAlt),
      codeblockDecoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(BloomDesign.radiusSm),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.divider, width: 1)),
      ),
      a: body.copyWith(color: p.period, decoration: TextDecoration.underline),
      strong: strong,
    );
  }
}

class _EmptyThread extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  const _EmptyThread({required this.suggestions, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        BloomDesign.gutter,
        40,
        BloomDesign.gutter,
        24,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: p.notesContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 36, color: p.notes),
          ),
          const SizedBox(height: 20),
          Text('Ask Bloom AI', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Bloom AI answers questions about cycles, symptoms, mood and partner support, using your own logged data.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: p.muted),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Try asking',
              style: theme.textTheme.titleSmall?.copyWith(color: p.muted),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSuggestion(s),
                  borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(BloomDesign.radiusMd),
                      border: Border.all(color: p.divider, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: p.notes,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: p.inkLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final enabled = _hasText && !widget.sending;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => widget.onSend(),
                  decoration: InputDecoration(
                    hintText: 'Ask about your cycle, symptoms or mood…',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BloomDesign.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BloomDesign.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BloomDesign.radiusLg),
                      borderSide: BorderSide(color: p.period, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: enabled ? p.period : p.surfaceHigh,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? widget.onSend : null,
                    child: widget.sending
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.arrow_upward_rounded,
                            color: enabled ? Colors.white : p.muted,
                            size: 22,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySheet extends StatelessWidget {
  final List<ChatConversation> conversations;
  final String? currentId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final void Function(String id, String currentTitle) onRename;
  final ValueChanged<String> onDelete;

  const _HistorySheet({
    required this.conversations,
    required this.currentId,
    required this.onSelect,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = BloomPalette.of(context);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: p.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chat History',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: p.period),
                    tooltip: 'New chat',
                    onPressed: onCreate,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: conversations.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'No conversations yet. Your chats are stored only on this device.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: p.muted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      itemBuilder: (context, i) {
                        final conv = conversations[i];
                        final selected = conv.id == currentId;
                        return ListTile(
                          selected: selected,
                          selectedTileColor: p.periodContainer,
                          title: Text(
                            conv.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: selected ? p.period : p.ink,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat('MMM d, h:mm a').format(conv.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: p.muted,
                            ),
                          ),
                          onTap: () => onSelect(conv.id),
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              size: 18,
                              color: p.muted,
                            ),
                            color: p.surface,
                            onSelected: (value) {
                              if (value == 'rename') {
                                onRename(conv.id, conv.title);
                              } else if (value == 'delete') {
                                onDelete(conv.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color: p.inkLight,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Rename'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: p.period,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: p.period),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
