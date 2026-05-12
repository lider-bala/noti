import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/animated_section_switcher.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/language_menu_button.dart';
import 'parent_attendance_screen.dart';
import 'parent_grades_screen.dart';
import 'parent_home_screen.dart';
import 'parent_homework_screen.dart';
import 'parent_notifications_screen.dart';
import 'parent_schedule_screen.dart';
import 'parent_settings_screen.dart';
import 'parent_side_menu.dart';
import 'parent_teachers_screen.dart';

class ParentMainScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ParentMainScreen({
    super.key,
    required this.onLogout,
  });

  @override
  State<ParentMainScreen> createState() => _ParentMainScreenState();
}

class _ParentMainScreenState extends State<ParentMainScreen> {
  ParentSection _section = ParentSection.home;
  bool _isMobileMenuOpen = false;

  String _titleForSection(BuildContext context, ParentSection section) {
    switch (section) {
      case ParentSection.home:
        return context.tr('section.home');
      case ParentSection.schedule:
        return context.tr('section.schedule');
      case ParentSection.homework:
        return context.tr('section.homework');
      case ParentSection.grades:
        return context.tr('section.grades');
      case ParentSection.attendance:
        return context.tr('section.attendance');
      case ParentSection.notifications:
        return context.tr('section.notifications');
      case ParentSection.teachers:
        return context.tr('section.teachers');
      case ParentSection.settings:
        return context.tr('section.settings');
    }
  }

  void _setSection(ParentSection section) {
    if (_section == section && !_isMobileMenuOpen) {
      return;
    }
    setState(() {
      _section = section;
      _isMobileMenuOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.appState.currentUser;

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
                      bottom: BorderSide(
                        color: context.appBorderColor,
                      ),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        color: Color(0x14000000),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isMobile)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Material(
                              color: const Color(0xFF2ECC71).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    _isMobileMenuOpen = true;
                                  });
                                },
                                child: const Icon(
                                  Icons.menu_rounded,
                                  size: 22,
                                  color: Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 40),
                        Text(
                          _titleForSection(context, _section),
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const LanguageMenuButton(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ParentSideMenu(
                            user: user,
                            current: _section,
                            onSelect: _setSection,
                            onLogout: widget.onLogout,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                        setState(() {
                          _isMobileMenuOpen = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 280,
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
                        child: ParentSideMenu(
                          user: user,
                          current: _section,
                          onSelect: _setSection,
                          onLogout: () {
                            setState(() {
                              _isMobileMenuOpen = false;
                            });
                            widget.onLogout();
                          },
                        ),
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
      case ParentSection.home:
        return ParentHomeScreen(onNavigate: _setSection);
      case ParentSection.schedule:
        return const ParentScheduleScreen();
      case ParentSection.homework:
        return const ParentHomeworkScreen();
      case ParentSection.grades:
        return const ParentGradesScreen();
      case ParentSection.attendance:
        return const ParentAttendanceScreen();
      case ParentSection.notifications:
        return const ParentNotificationsScreen();
      case ParentSection.teachers:
        return const ParentTeachersScreen();
      case ParentSection.settings:
        return const ParentSettingsScreen();
    }
  }
}
