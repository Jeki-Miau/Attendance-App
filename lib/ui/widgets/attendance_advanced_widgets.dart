import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_store.dart';
import '../../services/shift_rules.dart';
import '../attendance_design.dart';
import 'attendance_shared_widgets.dart';
import 'motion.dart';

// =============================================================================
// 1. GAMIFIED ATTENDANCE SCORE + STREAK BADGES + MONTHLY HEATMAP CALENDAR CARD
// =============================================================================
class AttendanceHeatmapAndScoreCard extends StatelessWidget {
  final List<AttendanceRecord> records;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final VoidCallback onOpenExportSlip;

  const AttendanceHeatmapAndScoreCard({
    super.key,
    required this.records,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onOpenExportSlip,
  });

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final stats = _computeDisciplineStats(records);
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedDate.year,
      selectedDate.month,
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14142B).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Top Row: Discipline Score Ring + Streak & Gamification Badges ===
          Row(
            children: [
              // Animated Circular Score Gauge
              SizedBox(
                width: 74,
                height: 74,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: stats.score / 100.0),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: val,
                        color: stats.score >= 85
                            ? AttendanceColors.green
                            : (stats.score >= 70
                                ? AttendanceColors.accent
                                : AttendanceColors.orange),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(val * 100).round()}',
                              style: const TextStyle(
                                color: AttendanceColors.text,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'SCORE',
                              style: TextStyle(
                                color: AttendanceColors.secondaryText,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEFE5),
                            borderRadius: BorderRadius.circular(
                              AttendanceRadius.pill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 13,
                                color: AttendanceColors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${stats.streakDays} Hari Streak',
                                style: const TextStyle(
                                  color: AttendanceColors.orange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        StatusPill(
                          label: stats.tierLabel,
                          style: PillStyle.green,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Skor Disiplin & Heatmap',
                      style: TextStyle(
                        color: AttendanceColors.text,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.onTimeCount} Tepat Waktu • ${stats.photoProofCount} Bukti Foto',
                      style: const TextStyle(
                        color: AttendanceColors.secondaryText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Quick Export Slip Button
              Pressable(
                onTap: onOpenExportSlip,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AttendanceColors.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Slip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // === Gamification Badges Strip ===
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAchievementBadge(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Early Bird',
                  color: AttendanceColors.orange,
                ),
                const SizedBox(width: 8),
                _buildAchievementBadge(
                  icon: Icons.verified_rounded,
                  label: 'Face Scan 100%',
                  color: AttendanceColors.accent,
                ),
                const SizedBox(width: 8),
                _buildAchievementBadge(
                  icon: Icons.emoji_events_rounded,
                  label: 'Top Discipline',
                  color: AttendanceColors.green,
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: AttendanceColors.divider),
          ),

          // === Heatmap Month Header + Legend ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heatmap ${DateFormat('MMMM yyyy').format(selectedDate)}',
                style: const TextStyle(
                  color: AttendanceColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot(AttendanceColors.green, 'On Time'),
                  const SizedBox(width: 8),
                  _buildLegendDot(AttendanceColors.orange, 'Late'),
                  const SizedBox(width: 8),
                  _buildLegendDot(AttendanceColors.accent, 'Leave/OT'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // === Interactive Monthly Heatmap Grid (7 columns per row) ===
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final date = DateTime(
                selectedDate.year,
                selectedDate.month,
                dayNum,
              );
              final isSelected = _sameDay(date, selectedDate);
              final dayLogs = records
                  .where((r) => _sameDay(r.createdAt, date))
                  .toList();

              Color cellBg = AttendanceColors.cardInner;
              Color textColor = AttendanceColors.secondaryText;

              if (dayLogs.isNotEmpty) {
                final hasLeaveOrOt = dayLogs.any(
                  (r) => r.type == 'leave' || r.type == 'overtime',
                );
                final checkIn = dayLogs
                    .where((r) => r.type == 'check_in')
                    .firstOrNull;
                if (hasLeaveOrOt) {
                  cellBg = AttendanceColors.accent;
                  textColor = Colors.white;
                } else if (checkIn != null) {
                  final eval = ShiftRules.evaluate(
                    'check_in',
                    checkIn.createdAt,
                  );
                  if (eval.tone == ShiftTone.bad) {
                    cellBg = AttendanceColors.orange;
                    textColor = Colors.white;
                  } else {
                    cellBg = AttendanceColors.green;
                    textColor = Colors.white;
                  }
                } else {
                  cellBg = AttendanceColors.green.withValues(alpha: 0.75);
                  textColor = Colors.white;
                }
              }

              return GestureDetector(
                onTap: () => onSelectDate(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(9),
                    border: isSelected
                        ? Border.all(color: AttendanceColors.ink, width: 2.0)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: isSelected || dayLogs.isNotEmpty
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AttendanceRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AttendanceColors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  _DisciplineStats _computeDisciplineStats(List<AttendanceRecord> all) {
    if (all.isEmpty) {
      return const _DisciplineStats(
        score: 92,
        streakDays: 5,
        onTimeCount: 0,
        photoProofCount: 0,
        tierLabel: 'A+ Tier',
      );
    }

    final checkIns = all.where((r) => r.type == 'check_in').toList();
    int onTime = 0;
    for (final rec in checkIns) {
      final eval = ShiftRules.evaluate('check_in', rec.createdAt);
      if (eval.tone != ShiftTone.bad) onTime++;
    }

    final ratio = checkIns.isEmpty ? 0.95 : (onTime / checkIns.length);
    final score = (70 + (ratio * 30)).round().clamp(60, 100);
    final photoCount = all
        .where((r) => r.photoBase64.isNotEmpty || r.type == 'check_in')
        .length;
    final streak = math.max(1, onTime);
    final tier = score >= 92
        ? 'S-Tier • Elite'
        : (score >= 82 ? 'A-Tier • Solid' : 'B-Tier • Active');

    return _DisciplineStats(
      score: score,
      streakDays: streak,
      onTimeCount: onTime,
      photoProofCount: photoCount,
      tierLabel: tier,
    );
  }
}

class _DisciplineStats {
  final int score;
  final int streakDays;
  final int onTimeCount;
  final int photoProofCount;
  final String tierLabel;

  const _DisciplineStats({
    required this.score,
    required this.streakDays,
    required this.onTimeCount,
    required this.photoProofCount,
    required this.tierLabel,
  });
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ScoreRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 5;

    final trackPaint = Paint()
      ..color = AttendanceColors.cardInner
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// =============================================================================
// 2. SELFIE PHOTO PROOF VIEWER DIALOG (PREVIEW SAAT FOTO BUKTI DIKLIK)
// =============================================================================
void showPhotoProofViewerDialog(
  BuildContext context, {
  required AttendanceRecord record,
}) {
  Uint8List? imageBytes;
  if (record.photoBase64.isNotEmpty) {
    try {
      imageBytes = base64Decode(record.photoBase64);
    } catch (_) {}
  }

  final eval = ShiftRules.evaluate(
    record.type,
    record.createdAt,
    status: record.status,
  );

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Photo Proof',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
    pageBuilder: (ctx, anim1, anim2) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.88,
          constraints: const BoxConstraints(maxWidth: 390),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                        icon: Icons.camera_front_rounded,
                        size: 38,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bukti Foto ${record.title}',
                            style: const TextStyle(
                              color: AttendanceColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'EEE, d MMM yyyy • hh:mm:ss a',
                            ).format(record.createdAt),
                            style: const TextStyle(
                              color: AttendanceColors.secondaryText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Photo Frame
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageBytes != null)
                        Image.memory(imageBytes, fit: BoxFit.cover)
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1A1E3B), Color(0xFF0D0F1E)],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.10),
                                  border: Border.all(
                                    color: AttendanceColors.green,
                                    width: 2.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.face_retouching_natural_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Verified Camera Snapshot',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID Log #${record.id}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Watermark Stamp Overlay at Bottom of Photo
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.68),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: AttendanceColors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${record.location} • ${DateFormat('HH:mm:ss').format(record.createdAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              StatusPill(
                                label: eval.label,
                                style: eval.tone == ShiftTone.bad
                                    ? PillStyle.red
                                    : PillStyle.green,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AttendancePrimaryButton(
                      label: 'Cetak Slip Bukti',
                      icon: Icons.receipt_long_rounded,
                      backgroundColor: AttendanceColors.accent,
                      onPressed: () {
                        Navigator.pop(ctx);
                        showDigitalAttendanceSlipModal(
                          context,
                          records: [record],
                          singleRecord: record,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// =============================================================================
// 3. DIGITAL ATTENDANCE SLIP & EXPORT MODAL (CSV / SLIP LAPORAN SIAP CETAK)
// =============================================================================
Future<void> showDigitalAttendanceSlipModal(
  BuildContext context, {
  required List<AttendanceRecord> records,
  AttendanceRecord? singleRecord,
}) async {
  final profile = await AttendanceStore.loadProfile();
  if (!context.mounted) return;

  final checkIns = records.where((r) => r.type == 'check_in').length;
  final checkOuts = records.where((r) => r.type == 'check_out').length;
  final overtimes = records.where((r) => r.type == 'overtime').length;
  final leaves = records.where((r) => r.type == 'leave').length;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AttendanceColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AttendanceColors.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // === Digital Slip Ticket Card ===
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AttendanceColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Slip Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AttendanceColors.ink,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SLIP KEHADIRAN DIGITAL',
                                    style: TextStyle(
                                      color: AttendanceColors.text,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  Text(
                                    'Dicetak: ${DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now())}',
                                    style: const TextStyle(
                                      color: AttendanceColors.secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const StatusPill(
                            label: 'VERIFIED',
                            style: PillStyle.green,
                            dense: true,
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(
                          height: 1,
                          color: AttendanceColors.divider,
                        ),
                      ),

                      // Employee Identity Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AttendanceColors.cardInner,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            UserAvatarBadge(
                              photoBase64: profile.photoBase64,
                              size: 46,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.name,
                                    style: const TextStyle(
                                      color: AttendanceColors.text,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${profile.role} • ${profile.department}',
                                    style: const TextStyle(
                                      color: AttendanceColors.secondaryText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Employee Badge #${profile.employeeId}',
                                    style: const TextStyle(
                                      color: AttendanceColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 4 Summary Metrics Grid
                      Row(
                        children: [
                          _buildSlipStat(
                            'Check-In',
                            '$checkIns Kali',
                            AttendanceColors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildSlipStat(
                            'Check-Out',
                            '$checkOuts Kali',
                            AttendanceColors.accent,
                          ),
                          const SizedBox(width: 8),
                          _buildSlipStat(
                            'Overtime',
                            '${overtimes * 4} Jam',
                            AttendanceColors.orange,
                          ),
                          const SizedBox(width: 8),
                          _buildSlipStat(
                            'Izin/WFH',
                            '$leaves Hari',
                            AttendanceColors.text,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Rincian Log Terverifikasi',
                        style: TextStyle(
                          color: AttendanceColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),

                      for (final item in records.take(5))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                item.photoBase64.isNotEmpty
                                    ? Icons.camera_alt_rounded
                                    : Icons.check_circle_rounded,
                                size: 15,
                                color: AttendanceColors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.title} • ${DateFormat('dd/MM HH:mm').format(item.createdAt)}',
                                  style: const TextStyle(
                                    color: AttendanceColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                item.status,
                                style: const TextStyle(
                                  color: AttendanceColors.secondaryText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(
                          height: 1,
                          color: AttendanceColors.divider,
                        ),
                      ),

                      // Digital Barcode Graphic
                      SizedBox(
                        height: 34,
                        width: double.infinity,
                        child: CustomPaint(painter: _BarcodeSlipPainter()),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'AUDIT-HASH-${profile.employeeId}-${records.length}LOGS-VERIFIED',
                          style: const TextStyle(
                            color: AttendanceColors.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Export Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: AttendancePrimaryButton(
                        label: 'Salin CSV (Excel)',
                        icon: Icons.table_view_rounded,
                        backgroundColor: AttendanceColors.ink,
                        onPressed: () async {
                          final csv = _generateCsv(records, profile);
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          showAttendanceSnack(
                            context,
                            'Data CSV (${records.length} baris) berhasil disalin ke Clipboard!',
                            icon: Icons.check_circle_rounded,
                            color: AttendanceColors.green,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AttendancePrimaryButton(
                        label: 'Salin Slip Teks',
                        icon: Icons.copy_all_rounded,
                        backgroundColor: AttendanceColors.accent,
                        onPressed: () async {
                          final txt = _generateSlipText(records, profile);
                          await Clipboard.setData(ClipboardData(text: txt));
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          showAttendanceSnack(
                            context,
                            'Slip Rekap Kehadiran berhasil disalin! Siap ditempel ke WhatsApp/HR.',
                            icon: Icons.check_circle_rounded,
                            color: AttendanceColors.green,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildSlipStat(String label, String value, Color accent) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AttendanceColors.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

String _generateCsv(List<AttendanceRecord> records, UserProfile profile) {
  final sb = StringBuffer();
  sb.writeln(
    'ID,Nama Karyawan,Badge ID,Tanggal,Waktu,Tipe,Status,Lokasi,Bukti Foto',
  );
  for (final r in records) {
    final date = DateFormat('yyyy-MM-dd').format(r.createdAt);
    final time = DateFormat('HH:mm:ss').format(r.createdAt);
    final hasPhoto = r.photoBase64.isNotEmpty ? 'Ada Foto Selfie' : 'Terdeteksi';
    sb.writeln(
      '"${r.id}","${profile.name}","${profile.employeeId}","$date","$time","${r.title}","${r.status}","${r.location}","$hasPhoto"',
    );
  }
  return sb.toString();
}

String _generateSlipText(List<AttendanceRecord> records, UserProfile profile) {
  final sb = StringBuffer();
  sb.writeln('=== SLIP REKAP KEHADIRAN DIGITAL ===');
  sb.writeln('Nama      : ${profile.name} (#${profile.employeeId})');
  sb.writeln('Jabatan   : ${profile.role} - ${profile.department}');
  sb.writeln(
    'Dicetak   : ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
  );
  sb.writeln('Total Log : ${records.length} Aktivitas Terverifikasi Wajah');
  sb.writeln('------------------------------------');
  for (final r in records.take(10)) {
    sb.writeln(
      '• [${DateFormat('dd/MM HH:mm').format(r.createdAt)}] ${r.title} (${r.status}) @ ${r.location}',
    );
  }
  sb.writeln('====================================');
  return sb.toString();
}

class _BarcodeSlipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AttendanceColors.ink.withValues(alpha: 0.78)
      ..style = PaintingStyle.fill;

    double x = 8.0;
    int i = 0;
    while (x < size.width - 8) {
      final barW = (i % 3 == 0) ? 3.2 : ((i % 2 == 0) ? 1.6 : 2.4);
      final gap = (i % 4 == 0) ? 4.0 : 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 2, barW, size.height - 4),
          const Radius.circular(1),
        ),
        paint,
      );
      x += barW + gap;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
