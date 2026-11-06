import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_store.dart';
import '../../services/shift_rules.dart';
import '../attendance_design.dart';
import 'attendance_advanced_widgets.dart';
import 'motion.dart';

// =============================================================================
// Vector City Map Canvas (used in Activity cards & Scan Screen Geofence card)
// =============================================================================
class VectorCityMapCanvas extends StatelessWidget {
  final int seed;
  final bool fadeLeft;

  const VectorCityMapCanvas({
    super.key,
    this.seed = 1,
    this.fadeLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CityMapPainter(seed: seed, fadeLeft: fadeLeft),
        size: Size.infinite,
      ),
    );
  }
}

class _CityMapPainter extends CustomPainter {
  final int seed;
  final bool fadeLeft;

  const _CityMapPainter({required this.seed, required this.fadeLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Base city block tint
    canvas.drawRect(rect, Paint()..color = const Color(0xFFEDEDF2));

    // Park polygons (soft mint green like the reference screenshots)
    final parkPaint = Paint()..color = const Color(0xFFC8F0D0);
    final parkPath1 = Path()
      ..moveTo(size.width * 0.56, size.height * 0.08)
      ..lineTo(size.width * 0.74, size.height * 0.02)
      ..lineTo(size.width * 0.80, size.height * 0.34)
      ..lineTo(size.width * 0.60, size.height * 0.38)
      ..close();
    canvas.drawPath(parkPath1, parkPaint);

    final parkPath2 = Path()
      ..moveTo(size.width * 0.84, size.height * 0.48)
      ..lineTo(size.width * 0.98, size.height * 0.42)
      ..lineTo(size.width * 0.99, size.height * 0.78)
      ..lineTo(size.width * 0.82, size.height * 0.74)
      ..close();
    canvas.drawPath(parkPath2, parkPaint);

    final parkPath3 = Path()
      ..moveTo(size.width * 0.14, size.height * 0.62)
      ..lineTo(size.width * 0.32, size.height * 0.56)
      ..lineTo(size.width * 0.35, size.height * 0.88)
      ..lineTo(size.width * 0.16, size.height * 0.90)
      ..close();
    canvas.drawPath(parkPath3, parkPaint);

    // Highlighted landmark blocks (soft warm peach/amber like the reference)
    final landmarkPaint = Paint()..color = const Color(0xFFF9DEC2);
    final landmarkBlock1 = Path()
      ..moveTo(size.width * 0.63, size.height * 0.42)
      ..lineTo(size.width * 0.77, size.height * 0.37)
      ..lineTo(size.width * 0.81, size.height * 0.60)
      ..lineTo(size.width * 0.67, size.height * 0.65)
      ..close();
    canvas.drawPath(landmarkBlock1, landmarkPaint);

    final landmarkBlock2 = Path()
      ..moveTo(size.width * 0.36, size.height * 0.14)
      ..lineTo(size.width * 0.50, size.height * 0.10)
      ..lineTo(size.width * 0.53, size.height * 0.30)
      ..lineTo(size.width * 0.39, size.height * 0.34)
      ..close();
    canvas.drawPath(landmarkBlock2, landmarkPaint);

    // Secondary darker grey blocks for depth
    final blockPaint = Paint()..color = const Color(0xFFE4E4EC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.42, size.height * 0.46, size.width * 0.17, size.height * 0.25),
        const Radius.circular(4),
      ),
      blockPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            size.width * 0.18, size.height * 0.18, size.width * 0.15, size.height * 0.28),
        const Radius.circular(4),
      ),
      blockPaint,
    );

    // Minor roads (white)
    final minorRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final shift = (seed % 5) * 0.015;
    for (final frac in [0.18, 0.36, 0.54, 0.72, 0.88]) {
      final x = size.width * (frac + shift);
      canvas.drawLine(
        Offset(x - size.width * 0.08, 0),
        Offset(x + size.width * 0.08, size.height),
        minorRoad,
      );
    }
    for (final frac in [0.22, 0.44, 0.68, 0.86]) {
      final y = size.height * frac;
      canvas.drawLine(
        Offset(0, y + size.height * 0.08),
        Offset(size.width, y - size.height * 0.08),
        minorRoad,
      );
    }

    // Major arterial avenues (thicker white + soft warm boulevard)
    final majorRoad = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    final avenue1 = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
          size.width * 0.48, size.height * 0.42, size.width, size.height * 0.16);
    canvas.drawPath(avenue1, majorRoad);

    final avenue2 = Path()
      ..moveTo(size.width * 0.46, 0)
      ..quadraticBezierTo(
          size.width * 0.62, size.height * 0.52, size.width * 0.74, size.height);
    canvas.drawPath(avenue2, majorRoad);

    // Boulevard warm highlight line
    final highlightRoad = Paint()
      ..color = const Color(0xFFF6C992).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(avenue1, highlightRoad);

    // Optional left-to-right white fade for Activity Cards
    if (fadeLeft) {
      final fadePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.94),
            Colors.white.withValues(alpha: 0.48),
            Colors.white.withValues(alpha: 0.18),
          ],
          stops: const [0.0, 0.34, 0.68, 1.0],
        ).createShader(rect);
      canvas.drawRect(rect, fadePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CityMapPainter old) =>
      old.seed != seed || old.fadeLeft != fadeLeft;
}

// =============================================================================
// Activity Card with Vector Map Background (matches Image 1 & Image 2)
// =============================================================================
class MapActivityCard extends StatelessWidget {
  final AttendanceRecord record;
  final int index;
  final VoidCallback? onTap;

  const MapActivityCard({
    super.key,
    required this.record,
    this.index = 0,
    this.onTap,
  });

  static IconData iconForType(String type) {
    return switch (type) {
      'check_in' => Icons.south_west_rounded,
      'check_out' => Icons.north_east_rounded,
      'break' => Icons.timer_outlined,
      'overtime' => Icons.date_range_rounded,
      'leave' => Icons.description_outlined,
      _ => Icons.south_west_rounded,
    };
  }

  static String displayTitleForType(String type, String fallback) {
    return switch (type) {
      'check_in' => 'Check in',
      'check_out' => 'Check out',
      'break' => 'Break',
      'overtime' => 'Overtime',
      _ => fallback,
    };
  }

  @override
  Widget build(BuildContext context) {
    final eval = ShiftRules.evaluate(
      record.type,
      record.createdAt,
      status: record.status,
    );

    final pillStyle = switch (eval.tone) {
      ShiftTone.good => PillStyle.orange,
      ShiftTone.bad => PillStyle.red,
      ShiftTone.neutral => PillStyle.indigo,
    };

    final timeDigits = DateFormat('hh:mm').format(record.createdAt);
    final amPm = DateFormat('a').format(record.createdAt).toUpperCase();
    final dateStr = DateFormat('EEE, MMM d yyyy').format(record.createdAt);
    final location = record.location.isEmpty
        ? 'Main Office - Entrance Gate'
        : record.location;

    return Pressable(
      onTap: onTap ?? () => _showRecordDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14142B).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              // Vector city map background
              Positioned.fill(
                child: VectorCityMapCanvas(
                  seed: record.id.hashCode + index,
                  fadeLeft: true,
                ),
              ),

              // Foreground content matching the reference layout
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Lavender icon badge + Title & Date + Status Pill
                    Row(
                      children: [
                        IconBadge(
                          icon: iconForType(record.type),
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitleForType(record.type, record.title),
                                style: const TextStyle(
                                  color: AttendanceColors.text,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: AttendanceColors.secondaryText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(label: eval.label, style: pillStyle),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Middle row: Large Time + AM/PM | divider | Delta ("12 Min Early")
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: AttendanceTypography.family,
                              ),
                              children: [
                                TextSpan(
                                  text: timeDigits,
                                  style: const TextStyle(
                                    color: AttendanceColors.text,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                TextSpan(
                                  text: ' $amPm',
                                  style: const TextStyle(
                                    color: AttendanceColors.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 1.2,
                            height: 20,
                            color: AttendanceColors.divider,
                          ),
                          const Spacer(),
                          Text(
                            eval.delta.isEmpty ? record.status : eval.delta,
                            style: const TextStyle(
                              color: AttendanceColors.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Bottom row: Location pin + Main Office - Entrance Gate + Photo Proof Pill
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AttendanceColors.lavender,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AttendanceColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AttendanceColors.secondaryText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => showPhotoProofViewerDialog(
                            context,
                            record: record,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(
                                AttendanceRadius.pill,
                              ),
                              border: Border.all(
                                color: AttendanceColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  record.photoBase64.isNotEmpty
                                      ? Icons.camera_alt_rounded
                                      : Icons.photo_camera_front_rounded,
                                  size: 13,
                                  color: AttendanceColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  record.photoBase64.isNotEmpty
                                      ? 'Foto Selfie'
                                      : 'Bukti Foto',
                                  style: const TextStyle(
                                    color: AttendanceColors.text,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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

  void _showRecordDetails(BuildContext context) {
    final eval = ShiftRules.evaluate(
      record.type,
      record.createdAt,
      status: record.status,
    );
    showAttendanceSheet(
      context: context,
      title: displayTitleForType(record.type, record.title),
      subtitle: DateFormat('EEEE, MMMM d yyyy • hh:mm:ss a').format(record.createdAt),
      children: [
        Container(
          height: 130,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AttendanceColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: VectorCityMapCanvas(seed: record.id.hashCode),
                ),
                const RadarPulseIndicator(size: 96),
              ],
            ),
          ),
        ),
        SheetActionTile(
          icon: Icons.photo_camera_front_rounded,
          title: 'Lihat Bukti Foto Selfie (Photo Proof)',
          subtitle: record.photoBase64.isNotEmpty
              ? 'Foto tangkapan kamera saat scan wajah tersimpan'
              : 'Lihat pratinjau snapshot verifikasi kamera',
          tint: AttendanceColors.accent,
          onTap: () {
            Navigator.pop(context);
            showPhotoProofViewerDialog(context, record: record);
          },
          trailing: const StatusPill(
            label: 'Preview',
            style: PillStyle.indigo,
          ),
        ),
        SheetActionTile(
          icon: Icons.receipt_long_rounded,
          title: 'Cetak Slip Bukti Kehadiran Digital',
          subtitle: 'Buka kartu slip resmi & salin format CSV / Teks',
          tint: AttendanceColors.orange,
          onTap: () {
            Navigator.pop(context);
            showDigitalAttendanceSlipModal(
              context,
              records: [record],
              singleRecord: record,
            );
          },
          trailing: const StatusPill(
            label: 'Slip',
            style: PillStyle.orange,
          ),
        ),
        SheetActionTile(
          icon: Icons.location_on_rounded,
          title: record.location.isEmpty
              ? 'Main Office - Entrance Gate'
              : record.location,
          subtitle: '${eval.label} • ${eval.delta}',
          onTap: () => Navigator.pop(context),
          trailing: StatusPill(
            label: eval.label,
            style: eval.tone == ShiftTone.bad ? PillStyle.red : PillStyle.orange,
          ),
        ),
        SheetActionTile(
          icon: Icons.face_retouching_natural_rounded,
          title: record.verificationBadge ?? 'Face Detected',
          subtitle: record.note.isEmpty
              ? 'Wajah berhasil terdeteksi saat scan'
              : record.note,
          tint: AttendanceColors.green,
          onTap: () => Navigator.pop(context),
          trailing: const StatusPill(
            label: 'Detected',
            style: PillStyle.green,
          ),
        ),
        SheetActionTile(
          icon: Icons.delete_outline_rounded,
          title: 'Remove log entry',
          subtitle: 'Delete this attendance record from device storage',
          tint: AttendanceColors.red,
          onTap: () async {
            Navigator.pop(context);
            await AttendanceStore.delete(record.id);
            if (context.mounted) {
              showAttendanceSnack(
                context,
                'Attendance log removed',
                icon: Icons.delete_outline_rounded,
              );
            }
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Concentric Animated Radar Pulse Indicator (seen on the Map in Image 2 & 3)
// =============================================================================
class RadarPulseIndicator extends StatefulWidget {
  final double size;

  const RadarPulseIndicator({super.key, this.size = 150});

  @override
  State<RadarPulseIndicator> createState() => _RadarPulseIndicatorState();
}

class _RadarPulseIndicatorState extends State<RadarPulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final pulseScale = 0.88 + 0.16 * math.sin(t * 2 * math.pi);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer translucent circle with thin indigo border (matches Image 2 & 3)
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AttendanceColors.accent.withValues(alpha: 0.13),
                    border: Border.all(
                      color: AttendanceColors.accent.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Middle concentric circle
              Transform.scale(
                scale: 1.0 - 0.08 * math.cos(t * 2 * math.pi),
                child: Container(
                  width: s * 0.56,
                  height: s * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AttendanceColors.accent.withValues(alpha: 0.18),
                  ),
                ),
              ),
              // Center white badge with indigo person icon
              Container(
                width: s * 0.28,
                height: s * 0.28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AttendanceColors.accent.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: s * 0.16,
                  color: AttendanceColors.accent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// User Avatar Badge (top-right of Home Screen & Profile Screen)
// =============================================================================
class UserAvatarBadge extends StatelessWidget {
  final String photoBase64;
  final double size;
  final VoidCallback? onTap;

  const UserAvatarBadge({
    super.key,
    required this.photoBase64,
    this.size = 52,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarContent;
    if (photoBase64.isNotEmpty) {
      try {
        avatarContent = Image.memory(
          base64Decode(photoBase64),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {
        avatarContent = CustomPaint(
          size: Size.square(size),
          painter: const _PortraitAvatarPainter(),
        );
      }
    } else {
      avatarContent = CustomPaint(
        size: Size.square(size),
        painter: const _PortraitAvatarPainter(),
      );
    }

    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(child: avatarContent),
      ),
    );
  }
}

class _PortraitAvatarPainter extends CustomPainter {
  const _PortraitAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Soft studio background matching Image 2's avatar
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6F6F9), Color(0xFFE4E6EE)],
        ).createShader(Offset.zero & size),
    );

    // Hair back
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.42),
      w * 0.27,
      Paint()..color = const Color(0xFF1F1D24),
    );

    // Shoulders / grey blazer + dark collar
    final blazerPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.5, h * 0.66, w * 0.88, h)
      ..close();
    canvas.drawPath(blazerPath, Paint()..color = const Color(0xFF6E7785));

    // Neck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.66),
          width: w * 0.18,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.06),
      ),
      Paint()..color = const Color(0xFFE5B89B),
    );

    // Face oval
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.44),
        width: w * 0.38,
        height: h * 0.44,
      ),
      Paint()..color = const Color(0xFFF1C7A8),
    );

    // Side-parted dark hair
    final hairFront = Path()
      ..moveTo(w * 0.28, h * 0.42)
      ..quadraticBezierTo(w * 0.34, h * 0.18, w * 0.55, h * 0.20)
      ..quadraticBezierTo(w * 0.72, h * 0.22, w * 0.72, h * 0.44)
      ..quadraticBezierTo(w * 0.62, h * 0.30, w * 0.46, h * 0.30)
      ..quadraticBezierTo(w * 0.34, h * 0.32, w * 0.28, h * 0.42)
      ..close();
    canvas.drawPath(hairFront, Paint()..color = const Color(0xFF1C1A22));

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF23202A);
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), w * 0.024, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.44), w * 0.024, eyePaint);

    // Warm smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.51),
        width: w * 0.14,
        height: h * 0.08,
      ),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFFB86B58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitAvatarPainter oldDelegate) => false;
}
