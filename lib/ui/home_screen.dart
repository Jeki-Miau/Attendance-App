import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/attendance_store.dart';
import '../services/shift_rules.dart';
import 'attend/attend_screen.dart';
import 'attendance_design.dart';
import 'navigation_shell.dart';
import 'widgets/attendance_advanced_widgets.dart';
import 'widgets/attendance_shared_widgets.dart';
import 'widgets/motion.dart';

/// Standalone Screen for backward compatibility
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigationShell(initialIndex: 0);
  }
}

/// Redesigned Home Screen matching the reference UI ("What's up, Chandra!",
/// 2x2 Overview Bento Grid, Recent Activity with Vector City Map cards,
/// and interactive shift analytics).
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  bool _loading = true;
  String? _loadError;
  List<AttendanceRecord> _records = const [];
  UserProfile? _profile;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    AttendanceStore.revision.addListener(_onStoreChanged);
    _loadData();
  }

  @override
  void dispose() {
    AttendanceStore.revision.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    _loadData(silent: true);
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final records = await AttendanceStore.load();
      final profile = await AttendanceStore.loadProfile();
      if (!mounted) return;
      setState(() {
        _records = records;
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load records: $e';
        _loading = false;
      });
    }
  }

  void _openAttendance(AttendanceAction action) {
    Navigator.push(
      context,
      SmoothPageRoute(page: AttendScreen(action: action)),
    ).then((_) => _loadData(silent: true));
  }

  Future<void> _pickOverviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final rawName = (_profile?.name ?? 'Chandra Pratama').trim();
    final firstName = rawName.isEmpty ? 'Chandra' : rawName.split(' ').first;

    final dayRecords = _records
        .where((r) => _sameDay(r.createdAt, _selectedDate))
        .toList();

    final todayCheckIn =
        dayRecords.where((r) => r.type == 'check_in').firstOrNull;
    final todayCheckOut =
        dayRecords.where((r) => r.type == 'check_out').firstOrNull;
    final todayBreak = dayRecords.where((r) => r.type == 'break').firstOrNull;

    final totalOvertimeHours =
        _records.where((r) => r.type == 'overtime').length * 4;
    final displayOvertimeHours =
        totalOvertimeHours == 0 ? 8 : totalOvertimeHours;
    final latestOvertime =
        _records.where((r) => r.type == 'overtime').firstOrNull;

    return AttendancePageFrame(
      onRefresh: () => _loadData(),
      header: _buildDarkHeader(firstName),
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Overview Title + Date Pill ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overview', style: AttendanceTypography.sectionTitle),
                DatePill(
                  date: _selectedDate,
                  onTap: _pickOverviewDate,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === 2x2 Overview Bento Grid (matches Image 2) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(
                  child: _buildCheckInCard(todayCheckIn),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCheckOutCard(todayCheckOut),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FadeSlideIn(
            delay: const Duration(milliseconds: 270),
            child: Row(
              children: [
                Expanded(
                  child: _buildBreakCard(todayBreak),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOvertimeCard(
                    displayOvertimeHours,
                    latestOvertime?.createdAt,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // === Live Working Hours Timer & Quick Face Scan Action Strip ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 330),
            child: _buildQuickFaceScanBanner(
              todayCheckIn,
              todayCheckOut,
              todayBreak,
            ),
          ),

          const SizedBox(height: 24),

          // === Recent Activity Header (matches Image 2) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 390),
            child: AttendanceSectionHeading(
              title: 'Recent Activity',
              trailing: 'See All',
              onTrailing: () {
                MainNavigationShell.maybeOf(context)?.switchToTab(1);
              },
            ),
          ),

          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AttendanceColors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _loadError!,
                style: const TextStyle(color: AttendanceColors.red),
              ),
            )
          else if (_records.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No attendance activity yet. Tap Check in to scan your face.',
                  style: AttendanceTypography.caption,
                ),
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < _records.take(4).length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 430 + i * 70),
                    child: MapActivityCard(
                      record: _records[i],
                      index: i,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 6),

          // === Live Activity Stream Insight Card ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 620),
            child: _buildWeeklyInsightCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkHeader(String firstName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Bar: Grid icon left, Bell + Avatar right (matches Image 2)
          Row(
            children: [
              FadeSlideIn(
                scaleFrom: 0.7,
                offset: Offset.zero,
                child: CircleIconButton(
                  icon: Icons.grid_view_rounded,
                  tooltip: 'Quick Actions',
                  onTap: _showQuickWorkspaceSheet,
                ),
              ),
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                scaleFrom: 0.7,
                offset: Offset.zero,
                child: CircleIconButton(
                  icon: Icons.notifications_rounded,
                  badge: true,
                  tooltip: 'Notifications',
                  onTap: _showNotificationsSheet,
                ),
              ),
              const SizedBox(width: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                scaleFrom: 0.7,
                offset: Offset.zero,
                child: UserAvatarBadge(
                  photoBase64: _profile?.photoBase64 ?? '',
                  size: 52,
                  onTap: () {
                    MainNavigationShell.maybeOf(context)?.switchToTab(4);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            offset: const Offset(-18, 0),
            child: const Text(
              'Time to do what you do best',
              style: AttendanceTypography.headerSubtitle,
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 160),
            offset: const Offset(-24, 0),
            child: Text(
              'What’s up, $firstName!',
              style: AttendanceTypography.headerTitle.copyWith(fontSize: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInCard(AttendanceRecord? checkIn) {
    final timeStr = checkIn != null
        ? DateFormat('hh:mm').format(checkIn.createdAt)
        : '09:10';
    final amPm = checkIn != null
        ? DateFormat('a').format(checkIn.createdAt).toUpperCase()
        : 'AM';
    final eval = checkIn != null
        ? ShiftRules.evaluate('check_in', checkIn.createdAt)
        : const ShiftEvaluation('On time', ShiftTone.good, '12 Min Early');

    return AttendanceCard(
      onTap: () => _openAttendance(AttendanceAction.checkIn),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.south_west_rounded, size: 34),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Check in',
                  style: AttendanceTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MoreDotsButton(
                onTap: () => _showCardActionSheet(AttendanceAction.checkIn),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: AttendanceTypography.family,
                    ),
                    children: [
                      TextSpan(
                        text: timeStr,
                        style: AttendanceTypography.bigNumber,
                      ),
                      TextSpan(
                        text: ' $amPm',
                        style: const TextStyle(
                          color: AttendanceColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StatusPill(
                label: eval.label,
                style: eval.tone == ShiftTone.bad
                    ? PillStyle.red
                    : PillStyle.orange,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            checkIn != null ? 'Checked in success' : 'Checked in success',
            style: AttendanceTypography.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutCard(AttendanceRecord? checkOut) {
    final hasRecord = checkOut != null;
    final timeStr = hasRecord
        ? DateFormat('hh:mm').format(checkOut.createdAt)
        : '--:--';
    final amPm = hasRecord
        ? DateFormat('a').format(checkOut.createdAt).toUpperCase()
        : '';

    return AttendanceCard(
      onTap: () => _openAttendance(AttendanceAction.checkOut),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.north_east_rounded, size: 34),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Check out',
                  style: AttendanceTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MoreDotsButton(
                onTap: () => _showCardActionSheet(AttendanceAction.checkOut),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: AttendanceTypography.family,
                    ),
                    children: [
                      TextSpan(
                        text: timeStr,
                        style: AttendanceTypography.bigNumber,
                      ),
                      if (amPm.isNotEmpty)
                        TextSpan(
                          text: ' $amPm',
                          style: const TextStyle(
                            color: AttendanceColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.only(right: 10),
                color: AttendanceColors.divider,
              ),
              StatusPill(
                label: hasRecord ? 'Done' : 'n/a',
                style: hasRecord ? PillStyle.orange : PillStyle.outline,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasRecord ? 'Checked out success' : "It's not time yet",
            style: AttendanceTypography.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakCard(AttendanceRecord? breakRecord) {
    final timeStr = breakRecord != null
        ? DateFormat('hh:mm').format(breakRecord.createdAt)
        : '11:40';
    final amPm = breakRecord != null
        ? DateFormat('a').format(breakRecord.createdAt).toUpperCase()
        : 'AM';
    final eval = breakRecord != null
        ? ShiftRules.evaluate('break', breakRecord.createdAt)
        : const ShiftEvaluation('Too Early', ShiftTone.bad, '20 Min Early');

    return AttendanceCard(
      onTap: () => _openAttendance(AttendanceAction.breakAction),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.timer_outlined, size: 34),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Break',
                  style: AttendanceTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MoreDotsButton(
                onTap: () => _showCardActionSheet(AttendanceAction.breakAction),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: AttendanceTypography.family,
                    ),
                    children: [
                      TextSpan(
                        text: timeStr,
                        style: AttendanceTypography.bigNumber,
                      ),
                      TextSpan(
                        text: ' $amPm',
                        style: const TextStyle(
                          color: AttendanceColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StatusPill(
                label: eval.label,
                style: eval.tone == ShiftTone.bad
                    ? PillStyle.red
                    : PillStyle.orange,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Break Ongoing',
            style: AttendanceTypography.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(int hours, DateTime? updatedAt) {
    final updateDate = updatedAt ?? DateTime.now().subtract(const Duration(days: 2));
    return AttendanceCard(
      onTap: () => _openAttendance(AttendanceAction.overtime),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.date_range_rounded, size: 34),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Overtime',
                  style: AttendanceTypography.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MoreDotsButton(
                onTap: () => _showCardActionSheet(AttendanceAction.overtime),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: AttendanceColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: 1,
                height: 20,
                color: AttendanceColors.divider,
              ),
              const Spacer(),
              CountUpText(
                value: hours,
                style: AttendanceTypography.bigNumber,
              ),
              const SizedBox(width: 4),
              const Text(
                'Hour',
                style: TextStyle(
                  color: AttendanceColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Update, ${DateFormat('MMM d yyyy').format(updateDate)}',
            style: AttendanceTypography.caption.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFaceScanBanner(
    AttendanceRecord? checkIn,
    AttendanceRecord? checkOut,
    AttendanceRecord? breakRec,
  ) {
    final checkedInToday = checkIn != null;
    final checkedOutToday = checkOut != null;

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, _) {
        final now = DateTime.now();
        const targetSeconds = 8 * 3600; // Target kerja 8 jam (28.800 detik)

        Duration elapsed = Duration.zero;
        if (checkIn != null) {
          final endRef = checkOut?.createdAt ?? now;
          elapsed = endRef.difference(checkIn.createdAt);
          if (elapsed.isNegative) elapsed = Duration.zero;
        }

        final elapsedSec = elapsed.inSeconds;
        final progress = (elapsedSec / targetSeconds).clamp(0.0, 1.0);
        final remainingSec =
            (targetSeconds - elapsedSec).clamp(0, targetSeconds);
        final remaining = Duration(seconds: remainingSec);
        final isOvertime = elapsedSec > targetSeconds;

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final hoursStr = twoDigits(elapsed.inHours);
        final minsStr = twoDigits(elapsed.inMinutes.remainder(60));
        final secsStr = twoDigits(elapsed.inSeconds.remainder(60));

        final remHours = twoDigits(remaining.inHours);
        final remMins = twoDigits(remaining.inMinutes.remainder(60));
        final remSecs = twoDigits(remaining.inSeconds.remainder(60));

        final statusLabel = checkedOutToday
            ? 'Shift Selesai • Total Jam Kerja'
            : (checkedInToday
                ? (isOvertime
                    ? 'Overtime Aktif • Melebihi Target 8 Jam'
                    : 'Sisa Waktu Kerja: $remHours:$remMins:$remSecs')
                : 'Belum Check in • Target Shift 08:00:00');

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AttendanceColors.ink,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AttendanceColors.ink.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5B5FF0),
                          AttendanceColors.accentDeep,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.timer_rounded,
                        size: 21,
                        color: Colors.white,
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
                            const Text(
                              'Live Working Hours',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            PulseDot(
                              color: checkedOutToday
                                  ? AttendanceColors.accentSoft
                                  : (checkedInToday
                                      ? AttendanceColors.green
                                      : AttendanceColors.orange),
                              size: 7,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AttendanceRadius.pill),
                    ),
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // === Digital Live Counter Boxes (HH : MM : SS) ===
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimerUnit(hoursStr, 'HOURS'),
                    _buildTimerColon(),
                    _buildTimerUnit(minsStr, 'MINUTES'),
                    _buildTimerColon(),
                    _buildTimerUnit(
                      secsStr,
                      'SECONDS',
                      highlight: checkedInToday && !checkedOutToday,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // === Animated Shift Progress Bar ===
              ClipRRect(
                borderRadius: BorderRadius.circular(AttendanceRadius.pill),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? AttendanceColors.green
                        : AttendanceColors.accent,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    checkIn != null
                        ? 'Masuk: ${DateFormat('hh:mm a').format(checkIn.createdAt)}'
                        : 'Shift Pagi: 09:00 AM',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    checkOut != null
                        ? 'Pulang: ${DateFormat('hh:mm a').format(checkOut.createdAt)}'
                        : (breakRec != null
                            ? 'Istirahat: ${DateFormat('hh:mm a').format(breakRec.createdAt)}'
                            : 'Target: 05:00 PM (8 Jam)'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.58),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // === Quick Face Scan Action Chips ===
              Row(
                children: [
                  Expanded(
                    child: _buildActionChip(
                      label: 'CHECK IN',
                      icon: Icons.south_west_rounded,
                      primary: !checkedInToday,
                      onTap: () => _openAttendance(AttendanceAction.checkIn),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionChip(
                      label: 'CHECK OUT',
                      icon: Icons.north_east_rounded,
                      primary: checkedInToday && !checkedOutToday,
                      onTap: () => _openAttendance(AttendanceAction.checkOut),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionChip(
                      label: 'BREAK',
                      icon: Icons.timer_outlined,
                      primary: false,
                      onTap: () =>
                          _openAttendance(AttendanceAction.breakAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimerUnit(
    String value,
    String label, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFF8C90FF) : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerColon() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        ':',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: primary
              ? AttendanceColors.accent
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AttendanceRadius.pill),
          border: Border.all(
            color: primary
                ? AttendanceColors.accentSoft.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyInsightCard() {
    final onTimeCount = _records
        .where((r) => r.status.toLowerCase().contains('time'))
        .length;
    final rate = _records.isEmpty
        ? 96
        : ((onTimeCount / _records.length) * 100).clamp(78, 99).round();

    return AttendanceCard(
      onTap: () => showDigitalAttendanceSlipModal(context, records: _records),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.receipt_long_rounded, size: 36),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Digital Slip & Attendance Score',
                      style: AttendanceTypography.cardTitle,
                    ),
                    Text(
                      'Ketuk untuk cetak slip rekap bulanan / salin CSV',
                      style: AttendanceTypography.caption,
                    ),
                  ],
                ),
              ),
              CountUpText(
                value: rate,
                suffix: '%',
                style: const TextStyle(
                  color: AttendanceColors.accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: rate / 100),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AttendanceColors.cardInner,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AttendanceColors.accent,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCardActionSheet(AttendanceAction action) {
    final title = switch (action) {
      AttendanceAction.checkIn => 'Check in Options',
      AttendanceAction.checkOut => 'Check out Options',
      AttendanceAction.breakAction => 'Break Options',
      AttendanceAction.overtime => 'Overtime Options',
    };
    showAttendanceSheet(
      context: context,
      title: title,
      subtitle: 'Biometric Face Scan & Shift Schedule (09:00 AM – 06:00 PM)',
      children: [
        SheetActionTile(
          icon: Icons.face_retouching_natural_rounded,
          title: 'Launch Face Scanner Now',
          subtitle: 'Verify your face via camera & record timestamp',
          onTap: () {
            Navigator.pop(context);
            _openAttendance(action);
          },
        ),
        SheetActionTile(
          icon: Icons.calendar_month_rounded,
          title: 'View Full Attendance History',
          subtitle: 'Inspect daily logs, project tasks & GPS locations',
          tint: AttendanceColors.orange,
          onTap: () {
            Navigator.pop(context);
            MainNavigationShell.maybeOf(context)?.switchToTab(1);
          },
        ),
      ],
    );
  }

  void _showQuickWorkspaceSheet() {
    showAttendanceSheet(
      context: context,
      title: 'Workspace & Quick Actions',
      subtitle: 'Jump to any attendance module or scan mode',
      children: [
        SheetActionTile(
          icon: Icons.south_west_rounded,
          title: 'Face Scan • Check in',
          subtitle: 'Morning arrival verification (Shift starts 09:00 AM)',
          onTap: () {
            Navigator.pop(context);
            _openAttendance(AttendanceAction.checkIn);
          },
        ),
        SheetActionTile(
          icon: Icons.timer_outlined,
          title: 'Face Scan • Break',
          subtitle: 'Record lunch or rest break session',
          tint: AttendanceColors.orange,
          onTap: () {
            Navigator.pop(context);
            _openAttendance(AttendanceAction.breakAction);
          },
        ),
        SheetActionTile(
          icon: Icons.north_east_rounded,
          title: 'Face Scan • Check out',
          subtitle: 'Complete today’s shift (Shift ends 06:00 PM)',
          tint: AttendanceColors.green,
          onTap: () {
            Navigator.pop(context);
            _openAttendance(AttendanceAction.checkOut);
          },
        ),
        SheetActionTile(
          icon: Icons.event_note_rounded,
          title: 'Request Absence / WFH',
          subtitle: 'Submit sick leave, annual leave, or remote work permit',
          onTap: () {
            Navigator.pop(context);
            MainNavigationShell.maybeOf(context)?.switchToTab(3);
          },
        ),
      ],
    );
  }

  void _showNotificationsSheet() {
    showAttendanceSheet(
      context: context,
      title: 'Notifications',
      subtitle: 'Live updates from your attendance & HR workspace',
      children: [
        SheetActionTile(
          icon: Icons.verified_user_rounded,
          title: 'Face Biometric Active',
          subtitle: 'Your face verification profile is synced for instant check-in.',
          tint: AttendanceColors.green,
          onTap: () => Navigator.pop(context),
        ),
        SheetActionTile(
          icon: Icons.location_on_rounded,
          title: 'Geofence Verified • Main Office',
          subtitle: 'Within 50m radius of Entrance Gate.',
          onTap: () => Navigator.pop(context),
        ),
        SheetActionTile(
          icon: Icons.schedule_rounded,
          title: 'Shift Reminder',
          subtitle: 'Regular shift runs 09:00 AM – 06:00 PM (Break 12:00 PM).',
          tint: AttendanceColors.orange,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
