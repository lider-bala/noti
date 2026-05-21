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
  String? _selectedUserId;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _selectedUserId == null) return;
    final appState = context.appState;
    final adminId = appState.currentUser?.id;
    if (adminId == null) return;
    final key = appState.chatKeyForUsers(adminId, _selectedUserId!);
    appState.addChatMessage(contactKey: key, message: text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _roleLabel(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return context.tr('role.teacher');
      case UserRole.student:
        return context.tr('role.student');
      case UserRole.parent:
        return context.tr('role.parent');
      case UserRole.admin:
        return context.tr('role.admin');
      default:
        return role.name;
    }
  }

  Color _roleColor(BuildContext context, UserRole role) {
    final dark = context.isDarkTheme;
    switch (role) {
      case UserRole.teacher:
        return dark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
      case UserRole.student:
        return dark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED);
      case UserRole.parent:
        return dark ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
      case UserRole.admin:
        return dark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final adminId = appState.currentUser?.id;

    final allUsers = <AppUser>[
      ...appState.teachers,
      ...appState.students,
      ...appState.parents,
    ];

    final filteredUsers = _searchQuery.isEmpty
        ? allUsers
        : allUsers
            .where((u) =>
                u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    // Sort: users with messages first, then alphabetically
    filteredUsers.sort((a, b) {
      final aKey =
          adminId != null ? appState.chatKeyForUsers(adminId, a.id) : '';
      final bKey =
          adminId != null ? appState.chatKeyForUsers(adminId, b.id) : '';
      final aMessages = appState.chatMessagesForContact(aKey);
      final bMessages = appState.chatMessagesForContact(bKey);
      if (aMessages.isNotEmpty && bMessages.isEmpty) return -1;
      if (aMessages.isEmpty && bMessages.isNotEmpty) return 1;
      if (aMessages.isNotEmpty && bMessages.isNotEmpty) {
        return bMessages.last.createdAt.compareTo(aMessages.last.createdAt);
      }
      return a.fullName.compareTo(b.fullName);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          if (_selectedUserId != null) {
            return _buildChatView(context, appState, adminId);
          }
          return _buildUserList(context, filteredUsers, appState, adminId);
        }

        return Row(
          children: [
            SizedBox(
              width: 320,
              child:
                  _buildUserList(context, filteredUsers, appState, adminId),
            ),
            VerticalDivider(width: 1, color: context.appBorderColor),
            Expanded(
              child: _selectedUserId != null
                  ? _buildChatView(context, appState, adminId)
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: context.secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Выберите пользователя для чата'),
                            style: TextStyle(
                              color: context.secondaryTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<AppUser> users,
    AppState appState,
    String? adminId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: context.primaryTextColor),
              decoration: InputDecoration(
                hintText: context.tr('Поиск пользователей...'),
                hintStyle: TextStyle(color: context.secondaryTextColor),
                prefixIcon:
                    Icon(Icons.search_rounded, color: context.secondaryTextColor),
                filled: true,
                fillColor: context.panelMutedColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          Divider(height: 1, color: context.appBorderColor),
          Expanded(
            child: users.isEmpty
                ? Center(
                    child: Text(
                      context.tr('Нет пользователей'),
                      style: TextStyle(color: context.secondaryTextColor),
                    ),
                  )
                : ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: context.appBorderColor),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected = user.id == _selectedUserId;
                      final chatKey = adminId != null
                          ? appState.chatKeyForUsers(adminId, user.id)
                          : '';
                      final messages =
                          appState.chatMessagesForContact(chatKey);
                      final lastMsg =
                          messages.isNotEmpty ? messages.last.text : null;

                      return Material(
                        color: isSelected
                            ? context.appBorderColor.withOpacity(0.5)
                            : Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedUserId = user.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      _roleColor(context, user.role).withOpacity(0.15),
                                  child: Text(
                                    user.initials,
                                    style: TextStyle(
                                      color: _roleColor(context, user.role),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: TextStyle(
                                          color: context.primaryTextColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lastMsg ??
                                            _roleLabel(context, user.role),
                                        style: TextStyle(
                                          color: context.secondaryTextColor,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (messages.isNotEmpty)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatView(
    BuildContext context,
    AppState appState,
    String? adminId,
  ) {
    final user = appState.userById(_selectedUserId!);
    final chatKey = adminId != null
        ? appState.chatKeyForUsers(adminId, _selectedUserId!)
        : '';
    final messages = appState.chatMessagesForContact(chatKey);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.appBorderColor),
              ),
            ),
            child: Row(
              children: [
                if (isMobile)
                  IconButton(
                    onPressed: () =>
                        setState(() => _selectedUserId = null),
                    icon: Icon(Icons.arrow_back_rounded,
                        color: context.primaryTextColor),
                  ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      _roleColor(context, user?.role ?? UserRole.student)
                          .withOpacity(0.15),
                  child: Text(
                    user?.initials ?? '?',
                    style: TextStyle(
                      color: _roleColor(context, user?.role ?? UserRole.student),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? context.tr('Пользователь'),
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _roleLabel(context, user?.role ?? UserRole.student),
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: context.secondaryTextColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('Нет сообщений'),
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('Напишите первое сообщение'),
                          style: TextStyle(
                            color: context.secondaryTextColor,
                            fontSize: 12,
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
                      final isMine = msg.senderId == adminId;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 340),
                          margin: EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? const Color(0xFF10B981)
                                : context.panelMutedColor,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMine ? 16 : 4),
                              bottomRight: Radius.circular(isMine ? 4 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white
                                      : context.primaryTextColor,
                                  fontSize: 14,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: isMine
                                      ? Colors.white70
                                      : context.secondaryTextColor,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.appBorderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 3,
                    style: TextStyle(color: context.primaryTextColor),
                    decoration: InputDecoration(
                      hintText: context.tr('Напишите сообщение...'),
                      hintStyle:
                          TextStyle(color: context.secondaryTextColor),
                      filled: true,
                      fillColor: context.panelMutedColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            BorderSide(color: context.appBorderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
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
    );
  }
}
