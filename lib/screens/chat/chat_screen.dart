import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _chatKey(BuildContext context) {
    final state = context.appState;
    final me = state.currentUser;
    final admin = state.firstAdmin;
    if (me == null || admin == null || me.id == admin.id) return null;
    return state.chatKeyForUsers(me.id, admin.id);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final key = _chatKey(context);
    if (key == null) return;
    context.appState.addChatMessage(contactKey: key, message: text);
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
    final admin = state.firstAdmin;
    final key = _chatKey(context);

    if (me == null || admin == null || key == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
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
      );
    }

    final messages = state.chatMessagesForContact(key);

    return Container(
      constraints: const BoxConstraints(maxWidth: 700),
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
          _ChatHeader(
            name: admin.fullName,
            subtitle: context.tr('role.admin'),
            initials: admin.initials,
          ),
          Divider(height: 1, color: context.appBorderColor),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 48, color: context.secondaryTextColor),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('chat.startConversation'),
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return _ChatBubble(
                        text: msg.text,
                        isMine: msg.senderId == me.id,
                        time: msg.createdAt,
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: context.appBorderColor),
          _MessageInput(
            controller: _controller,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String initials;

  const _ChatHeader({
    required this.name,
    required this.subtitle,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: context.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  borderSide: BorderSide(color: context.appBorderColor),
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
