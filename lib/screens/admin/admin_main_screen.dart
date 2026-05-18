import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/animated_section_switcher.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/language_menu_button.dart';
import 'admin_academics_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_schedule_views.dart';
import 'admin_settings_screen.dart';
import 'admin_side_menu.dart';
import 'admin_users_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const AdminMainScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  AdminSection _section = AdminSection.overview;
  bool _isMobileMenuOpen = false;

  void _setSection(AdminSection section) {
    if (_section == section && !_isMobileMenuOpen) {
      return;
    }
    setState(() {
      _section = section;
      _isMobileMenuOpen = false;
    });
  }

  String _titleForSection(BuildContext context, AdminSection section) {
    switch (section) {
      case AdminSection.overview:
        return context.tr('section.overview');
      case AdminSection.users:
        return context.tr('section.users');
      case AdminSection.academics:
        return context.tr('section.academics');
      case AdminSection.classSchedule:
        return context.tr('Расписание классов');
      case AdminSection.teacherSchedule:
        return context.tr('Расписание учителей');
      case AdminSection.chat:
        return context.tr('Чат');
      case AdminSection.analytics:
        return context.tr('section.analytics');
      case AdminSection.settings:
        return context.tr('section.settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            final content = Column(
              children: [
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.topBarColor,
                    border: Border(
                      bottom: BorderSide(color: context.appBorderColor),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (isMobile)
                        IconButton(
                          onPressed: () {
                            setState(() => _isMobileMenuOpen = true);
                          },
                          icon: Icon(Icons.menu_rounded),
                        )
                      else
                        const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          _titleForSection(context, _section),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const LanguageMenuButton(),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: AdminSideMenu(
                            current: _section,
                            onSelect: _setSection,
                            onLogout: widget.onLogout,
                          ),
                        ),
                      Expanded(
                        child: _section == AdminSection.chat
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                child: _buildSection(),
                              )
                            : Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 24),
                                child: SingleChildScrollView(
                                  child: AnimatedSectionSwitcher(
                                    switchKey: _section,
                                    child: _buildSection(),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            return Stack(
              children: [
                content,
                if (isMobile && _isMobileMenuOpen) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isMobileMenuOpen = false);
                      },
                      child: Container(color: Colors.black.withOpacity(0.4)),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 292,
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.panelColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 24,
                            offset: Offset(8, 0),
                            color: Color(0x33000000),
                          ),
                        ],
                      ),
                      child: AdminSideMenu(
                        current: _section,
                        onSelect: _setSection,
                        onLogout: () {
                          setState(() => _isMobileMenuOpen = false);
                          widget.onLogout();
                        },
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection() {
    switch (_section) {
      case AdminSection.overview:
        return AdminOverviewScreen(
          onShowAllRequests: () => _setSection(AdminSection.users),
        );
      case AdminSection.users:
        return const AdminUsersScreen();
      case AdminSection.academics:
        return const AdminAcademicsScreen();
      case AdminSection.classSchedule:
        return const AdminClassScheduleScreen();
      case AdminSection.teacherSchedule:
        return const AdminTeacherScheduleScreen();
      case AdminSection.chat:
        return const AdminChatScreen();
      case AdminSection.analytics:
        return const AdminAnalyticsScreen();
      case AdminSection.settings:
        return const AdminSettingsScreen();
    }
  }
}
