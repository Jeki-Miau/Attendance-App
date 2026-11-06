import 'package:flutter/material.dart';

import 'absent/absent_screen.dart';
import 'attend/attend_screen.dart';
import 'attendance_design.dart';
import 'attendance_history/attendance_history_screen.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';

/// Main Shell with Persistent Frosted Floating Bottom Navigation across all tabs.
/// Tab layout matches the reference images:
///   0: Home
///   1: Attendance History (calendar icon)
///   2: Face Scan (center bracket-face glyph — opens AttendScreen)
///   3: Leave / Request Absence
///   4: Profile / Settings
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  static MainNavigationShellState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationShellState>();
  }

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final AnimationController _navEntryController;
  late final Animation<double> _navFade;
  late final Animation<Offset> _navSlide;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _navEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _navFade = CurvedAnimation(
      parent: _navEntryController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 1.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navEntryController,
      curve: const Interval(0.15, 0.9, curve: Curves.easeOutBack),
    ));

    _navEntryController.forward();
  }

  @override
  void dispose() {
    _navEntryController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    _onTabChange(index);
  }

  void _onTabChange(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        SmoothPageRoute(
          page: const AttendScreen(action: AttendanceAction.checkIn),
        ),
      );
      return;
    }
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreenContent(),
      const AttendanceHistoryContent(),
      const SizedBox.shrink(), // Center Face Scan trigger
      const AbsentContent(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AttendanceColors.ink,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_currentIndex),
              child: screens[_currentIndex],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _navSlide,
              child: FadeTransition(
                opacity: _navFade,
                child: AttendanceBottomNavigation(
                  currentIndex: _currentIndex,
                  onTap: _onTabChange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
