import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/animated_section_switcher.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/language_menu_button.dart';
import '../../widgets/side_menu.dart';
import 'attendance_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'homework_screen.dart';
import 'students_screen.dart';
import 'teachers_screen.dart';
import 'grades_screen.dart';
import 'files_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const MainScreen({super.key, required this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  MainSection _section = MainSection.home;
  String? _attendanceLessonId;
  bool _isMobileMenuOpen = false;

  String _titleForSection(BuildContext context, MainSection section) {
    switch (section) {
      case MainSection.home:
        return context.tr('section.home');
      case MainSection.schedule:
        return context.tr('section.schedule');
      case MainSection.attendance:
        return context.tr('Посещаемость');
      case MainSection.homework:
        return context.tr('section.homework');
      case MainSection.grades:
        return context.tr('section.grades');
      case MainSection.students:
        return context.tr('section.students');
      case MainSection.teachers:
        return context.tr('section.teachers');
      case MainSection.files:
        return context.tr('section.files');
      case MainSection.settings:
        return context.tr('section.settings');
    }
  }

  void _setSection(MainSection value) {
    if (_section == value && !_isMobileMenuOpen) {
      return;
    }
    setState(() {
      _section = value;
      _isMobileMenuOpen = false;
    });
  }

  void _openAttendance(String lessonId) {
    setState(() {
      _section = MainSection.attendance;
      _attendanceLessonId = lessonId;
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: 22,
                                  color: const Color(0xFF2ECC71),
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 40),
                        Text(
                          _titleForSection(context, _section),
                          style: TextStyle(
                            color: context.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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
                          child: SideMenu(
                            user: user,
                            current: _section,
                            onSelect: _setSection,
                            onLogout: widget.onLogout,
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: _section == MainSection.grades
                              ? AnimatedSectionSwitcher(
                                  switchKey: _section,
                                  child: _buildSection(),
                                )
                              : SingleChildScrollView(
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
                        margin: EdgeInsets.only(top: 8, bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.panelColor,
                          borderRadius: BorderRadius.only(
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
                        child: SideMenu(
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
      case MainSection.home:
        return const HomeScreen();
      case MainSection.schedule:
        return ScheduleScreen(
          onOpenSection: _setSection,
          onOpenAttendance: _openAttendance,
        );
      case MainSection.attendance:
        return AttendanceScreen(
          initialLessonId: _attendanceLessonId,
          onSaved: () => _setSection(MainSection.schedule),
        );
      case MainSection.homework:
        return const HomeworkScreen();
      case MainSection.students:
        return const StudentsScreen();
      case MainSection.teachers:
        return const TeachersScreen();
      case MainSection.grades:
        return const GradesScreen();
      case MainSection.files:
        return const FilesScreen();
      case MainSection.settings:
        return const SettingsScreen();
    }
  }
}
