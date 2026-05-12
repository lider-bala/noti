import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/user_role.dart';
import '../../widgets/app_theme.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String? _selectedContactKey;
  String? _selectedContactName;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _selectedContactKey == null) return;
    context.appState
        .addChatMessage(contactKey: _selectedContactKey!, message: text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final me = state.currentUser;
    if (me == null) return const SizedBox.shrink();

    final conversations = _buildConversationList(state, me.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: _ConversationList(
                  conversations: conversations,
                  selectedKey: _selectedContactKey,
                  onSelect: (key, name) {
                    setState(() {
                      _selectedContactKey = key;
                      _selectedContactName = name;
                    });
                    _scrollToBottom();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _selectedContactKey != null
                    ? _ChatPanel(
                        contactKey: _selectedContactKey!,
                        contactName: _selectedContactName ?? '',
                        controller: _controller,
                        scrollController: _scrollController,
                        onSend: _send,
                        myId: me.id,
                      )
                    : _EmptyChatPanel(),
              ),
            ],
          );
        }

        if (_selectedContactKey != null) {
          return _ChatPanel(
            contactKey: _selectedContactKey!,
            contactName: _selectedContactName ?? '',
            controller: _controller,
            scrollController: _scrollController,
            onSend: _send,
            myId: me.id,
            onBack: () => setState(() {
              _selectedContactKey = null;
              _selectedContactName = null;
            }),
          );
        }

        return _ConversationList(
          conversations: conversations,
          selectedKey: _selectedContactKey,
          onSelect: (key, name) {
            setState(() {
              _selectedContactKey = key;
              _selectedContactName = name;
            });
            _scrollToBottom();
          },
        );
      },
    );
  }

  List<_ConversationEntry> _buildConversationList(
      AppState state, String myId) {
    final allMessages = state.allChatMessages;
    final entries = <_ConversationEntry>[];

    for (final entry in allMessages.entries) {
      final key = entry.key;
      final messages = entry.value;
      if (messages.isEmpty) continue;

      final parts = key.split(':');
      if (parts.length != 2) continue;

      final otherUserId = parts[0] == myId ? parts[1] : parts[0];
      final otherUser = state.userById(otherUserId);
      final name = otherUser?.fullName ?? otherUserId;
      final role = otherUser?.role;
      final lastMessage = messages.last;

      entries.add(_ConversationEntry(
        contactKey: key,
        name: name,
        role: role,
        lastMessage: lastMessage.text,
        lastTime: lastMessage.createdAt,
        initials: otherUser?.initials ?? '?',
      ));
    }

    entries.sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return entries;
  }
}

class _ConversationEntry {
  final String contactKey;
  final String name;
  final UserRole? role;
  final String lastMessage;
  final DateTime lastTime;
  final String initials;

  const _ConversationEntry({
    required this.contactKey,
    required this.name,
    required this.role,
    required this.lastMessage,
    required this.lastTime,
    required this.initials,
  });
}

class _ConversationList extends StatelessWidget {
  final List<_ConversationEntry> conversations;
  final String? selectedKey;
  final void Function(String key, String name) onSelect;

  const _ConversationList({
    required this.conversations,
    required this.selectedKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              context.tr('chat.conversations'),
              style: TextStyle(
                color: context.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Divider(height: 1, color: context.appBorderColor),
          if (conversations.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forum_outlined,
                        size: 48, color: context.secondaryTextColor),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('chat.noConversations'),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.tr('chat.noConversationsHint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: conversations.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, indent: 72, color: context.appBorderColor),
                itemBuilder: (context, index) {
                  final conv = conversations[index];
                  final isSelected = conv.contactKey == selectedKey;
                  return _ConversationTile(
                    entry: conv,
                    isSelected: isSelected,
                    onTap: () => onSelect(conv.contactKey, conv.name),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _ConversationEntry entry;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  String _roleLabel(BuildContext context, UserRole? role) {
    if (role == null) return '';
    return context.strings.role(role);
  }

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${entry.lastTime.hour.toString().padLeft(2, '0')}:${entry.lastTime.minute.toString().padLeft(2, '0')}';

    return Material(
      color: isSelected
          ? const Color(0xFF10B981).withOpacity(0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    entry.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (entry.role != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _roleLabel(context, entry.role),
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            entry.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined,
                size: 64, color: context.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              context.tr('chat.noMessages'),
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final String contactKey;
  final String contactName;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final String myId;
  final VoidCallback? onBack;

  const _ChatPanel({
    required this.contactKey,
    required this.contactName,
    required this.controller,
    required this.scrollController,
    required this.onSend,
    required this.myId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final messages = context.appState.chatMessagesForContact(contactKey);

    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 24,
            offset: Offset(0, 12),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _initials(contactName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    contactName,
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorderColor),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      context.tr('chat.noMessages'),
                      style: TextStyle(
                        color: context.secondaryTextColor,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _ChatBubble(
                        text: msg.text,
                        isMine: msg.senderId == myId,
                        time: msg.createdAt,
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: context.appBorderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: context.tr('chat.typeMessage'),
                      filled: true,
                      fillColor: context.panelMutedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: context.appBorderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(color: context.primaryTextColor),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton(
                    onPressed: onSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime time;

  const _ChatBubble({
    required this.text,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF10B981) : context.panelMutedColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : context.primaryTextColor,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMine
                    ? Colors.white.withOpacity(0.7)
                    : context.secondaryTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = parts.first.characters.first.toUpperCase();
  if (parts.length == 1) return first;
  return '$first${parts[1].characters.first.toUpperCase()}';
}
