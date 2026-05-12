import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_state.dart';
import 'app_feedback.dart';
import 'app_theme.dart';

String _phoneUriValue(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9+]'), '');
}

Future<void> openPhoneDialer(BuildContext context, String phone) async {
  final normalized = _phoneUriValue(phone);
  if (normalized.isEmpty) {
    showAppSnackBar(
      context,
      context.tr('Номер телефона не указан.'),
      backgroundColor: const Color(0xFFB91C1C),
    );
    return;
  }

  final uri = Uri(scheme: 'tel', path: normalized);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || launched) {
    return;
  }
  showAppSnackBar(
    context,
    context.tr('Не удалось открыть звонок на этом устройстве.'),
    backgroundColor: const Color(0xFFB91C1C),
  );
}

Future<void> openContactChat({
  required BuildContext context,
  required String contactId,
  required String name,
  required String subtitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _ContactChatSheet(
        contactId: contactId,
        name: name,
        subtitle: subtitle,
      );
    },
  );
}

class _ContactChatSheet extends StatefulWidget {
  final String contactId;
  final String name;
  final String subtitle;

  const _ContactChatSheet({
    required this.contactId,
    required this.name,
    required this.subtitle,
  });

  @override
  State<_ContactChatSheet> createState() => _ContactChatSheetState();
}

class _ContactChatSheetState extends State<_ContactChatSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    context.appState
        .addChatMessage(contactKey: _contactKey(context), message: text);
    _controller.clear();
  }

  String _contactKey(BuildContext context) {
    final currentUserId = context.appState.currentUser?.id;
    if (currentUserId == null) {
      return widget.contactId;
    }
    return context.appState.chatKeyForUsers(currentUserId, widget.contactId);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final currentUserId = context.appState.currentUser?.id;
    final messages =
        context.appState.chatMessagesForContact(_contactKey(context));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: context.appBorderColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
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
                        _initials(widget.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.appBorderColor),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ChatBubble(
                    text: context.tr(
                      'Здравствуйте. Чем могу помочь?',
                    ),
                    isMine: false,
                  ),
                  for (final message in messages)
                    _ChatBubble(
                      text: message.text,
                      isMine: message.senderId == currentUserId,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('Напишите сообщение...'),
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
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: _send,
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
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMine;

  const _ChatBubble({
    required this.text,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
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
        child: Text(
          text,
          style: TextStyle(
            color: isMine ? Colors.white : context.primaryTextColor,
            fontSize: 14,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return '?';
  }
  final first = parts.first.characters.first.toUpperCase();
  if (parts.length == 1) {
    return first;
  }
  return '$first${parts[1].characters.first.toUpperCase()}';
}
