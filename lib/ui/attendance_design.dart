import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widgets/motion.dart';

/// "Midnight & Paper" design system — dark header, light sheets, indigo accent.
/// Mirrors the reference Attendance UI (Overview cards, black week strip,
/// orange "On time" pills, floating frosted navigation).
abstract final class AttendanceColors {
  // Dark header / chrome
  static const ink = Color(0xFF0B0B0F);
  static const darkCanvas = ink;
  static const inkRaised = Color(0xFF1C1C24);
  static const inkBorder = Color(0x1AFFFFFF);
  static const navyGlow = Color(0xFF262A5C);
  static const page = ink;

  // Light canvas
  static const sheet = Color(0xFFF1F1F4);
  static const sheetCanvas = sheet;
  static const card = Colors.white;
  static const cardInner = Color(0xFFF6F6F9);
  static const border = Color(0xFFE7E7EE);
  static const divider = Color(0xFFE2E2E9);

  // Accent (indigo)
  static const accent = Color(0xFF4B4FDF);
  static const accentDeep = Color(0xFF3336B5);
  static const accentSoft = Color(0xFF8C8FF2);
  static const lavender = Color(0xFFE9E9FC);
  static const accentSurface = lavender;
  static const lavenderStrong = Color(0xFFD5D6F8);

  // Status
  static const orange = Color(0xFFF2782B);
  static const red = Color(0xFFEF4747);
  static const green = Color(0xFF1DB46A);
  static const success = green;
  static const warning = orange;
  static const error = red;

  // Typography
  static const text = Color(0xFF111117);
  static const secondaryText = Color(0xFF7A7A86);
  static const textMuted = Color(0xFFAAAAB5);

  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF09090C), Color(0xFF0E0E14), Color(0xFF1A1C3B)],
    stops: [0.0, 0.55, 1.0],
  );
}

abstract final class AttendanceSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class AttendanceRadius {
  static const sheet = 34.0;
  static const card = 24.0;
  static const compact = 16.0;
  static const pill = 100.0;
}

abstract final class AttendanceTypography {
  static const family = 'Manrope';

  static const headerTitle = TextStyle(
    fontFamily: family,
    color: Colors.white,
    fontSize: 27,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );
  static const headerSubtitle = TextStyle(
    fontFamily: family,
    color: Color(0xFF9A9AA6),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const sectionTitle = TextStyle(
    fontFamily: family,
    color: AttendanceColors.text,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const cardTitle = TextStyle(
    fontFamily: family,
    color: AttendanceColors.text,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const body = TextStyle(
    fontFamily: family,
    color: AttendanceColors.text,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const caption = TextStyle(
    fontFamily: family,
    color: AttendanceColors.secondaryText,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );
  static const bigNumber = TextStyle(
    fontFamily: family,
    color: AttendanceColors.text,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const buttonLabel = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
}

/// Smooth iOS-like slide & fade page route transition
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

abstract final class AttendanceTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AttendanceTypography.family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AttendanceColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AttendanceColors.accent,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: AttendanceColors.text,
        error: AttendanceColors.red,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AttendanceColors.sheet,
      textTheme: base.textTheme.apply(
        fontFamily: AttendanceTypography.family,
        bodyColor: AttendanceColors.text,
        displayColor: AttendanceColors.text,
      ),
      splashFactory: InkSparkle.splashFactory,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AttendanceColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: AttendanceTypography.family,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: StadiumBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

// =============================================================================
// Animated dark header background (slowly drifting aurora glow)
// =============================================================================
class DarkHeaderBackground extends StatefulWidget {
  const DarkHeaderBackground({super.key});

  @override
  State<DarkHeaderBackground> createState() => _DarkHeaderBackgroundState();
}

class _DarkHeaderBackgroundState extends State<DarkHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _AuroraPainter(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  _AuroraPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = AttendanceColors.headerGradient.createShader(rect),
    );

    final a = t * 2 * math.pi;
    void blob(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    blob(
      Offset(size.width * (0.82 + 0.10 * math.sin(a)),
          size.height * (0.92 + 0.06 * math.cos(a))),
      size.width * 0.75,
      AttendanceColors.accent.withValues(alpha: 0.30),
    );
    blob(
      Offset(size.width * (0.12 + 0.08 * math.cos(a * 1.3)),
          size.height * (0.70 + 0.08 * math.sin(a * 0.7))),
      size.width * 0.55,
      const Color(0xFF6C4BDF).withValues(alpha: 0.16),
    );
    blob(
      Offset(size.width * (0.55 + 0.15 * math.sin(a * 0.6)), size.height * 0.05),
      size.width * 0.45,
      Colors.white.withValues(alpha: 0.035),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.t != t;
}

// =============================================================================
// Tab page frame: dark header scrolling into a rounded light sheet
// =============================================================================
class AttendancePageFrame extends StatelessWidget {
  final Widget header;
  final Widget sheet;
  final Future<void> Function()? onRefresh;
  final EdgeInsets sheetPadding;

  const AttendancePageFrame({
    super.key,
    required this.header,
    required this.sheet,
    this.onRefresh,
    this.sheetPadding = const EdgeInsets.fromLTRB(16, 22, 16, 130),
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    Widget scroll = CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            offset: const Offset(0, 60),
            duration: const Duration(milliseconds: 800),
            child: Container(
              constraints: BoxConstraints(minHeight: height * 0.7),
              padding: sheetPadding,
              decoration: const BoxDecoration(
                color: AttendanceColors.sheet,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AttendanceRadius.sheet),
                ),
              ),
              child: sheet,
            ),
          ),
        ),
      ],
    );

    if (onRefresh != null) {
      scroll = RefreshIndicator(
        color: AttendanceColors.accent,
        backgroundColor: Colors.white,
        onRefresh: onRefresh!,
        child: scroll,
      );
    }

    return ColoredBox(
      color: AttendanceColors.ink,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 460,
            child: DarkHeaderBackground(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.45,
            child: const ColoredBox(color: AttendanceColors.sheet),
          ),
          SafeArea(bottom: false, child: scroll),
        ],
      ),
    );
  }
}

/// Header block: "View your attendance details" + big title + trailing buttons
class AttendanceHeader extends StatelessWidget {
  final String subtitle;
  final String title;
  final List<Widget> actions;
  final Widget? leading;

  const AttendanceHeader({
    super.key,
    required this.subtitle,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  offset: const Offset(-18, 0),
                  child: Text(subtitle, style: AttendanceTypography.headerSubtitle),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  offset: const Offset(-24, 0),
                  child: Text(title, style: AttendanceTypography.headerTitle),
                ),
              ],
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            const SizedBox(width: 10),
            FadeSlideIn(
              delay: Duration(milliseconds: 140 + i * 70),
              scaleFrom: 0.6,
              offset: Offset.zero,
              child: actions[i],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Primitive components
// =============================================================================
class CircleIconButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onTap;
  final bool dark;
  final double size;
  final bool badge;
  final String? tooltip;

  const CircleIconButton({
    super.key,
    this.icon,
    this.child,
    this.onTap,
    this.dark = true,
    this.size = 52,
    this.badge = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AttendanceColors.text;
    final button = Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AttendanceColors.inkRaised : Colors.white,
          border: Border.all(
            color: dark ? AttendanceColors.inkBorder : AttendanceColors.border,
          ),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            child ?? Icon(icon, color: fg, size: size * 0.4),
            if (badge)
              Positioned(
                top: size * 0.26,
                right: size * 0.28,
                child: const PulseDot(color: AttendanceColors.orange, size: 8),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Lavender circle with indigo icon — used on every Overview card
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  const IconBadge({
    super.key,
    required this.icon,
    this.size = 36,
    this.background = AttendanceColors.lavender,
    this.foreground = AttendanceColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: foreground),
    );
  }
}

enum PillStyle { orange, red, green, indigo, outline, dark }

class StatusPill extends StatelessWidget {
  final String label;
  final PillStyle style;
  final bool dense;

  const StatusPill({
    super.key,
    required this.label,
    this.style = PillStyle.orange,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color? border) = switch (style) {
      PillStyle.orange => (AttendanceColors.orange, Colors.white, null),
      PillStyle.red => (AttendanceColors.red, Colors.white, null),
      PillStyle.green => (AttendanceColors.green, Colors.white, null),
      PillStyle.indigo => (AttendanceColors.accent, Colors.white, null),
      PillStyle.dark => (AttendanceColors.ink, Colors.white, null),
      PillStyle.outline => (Colors.transparent, AttendanceColors.secondaryText,
          AttendanceColors.textMuted),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AttendanceRadius.pill),
        border: border == null ? null : Border.all(color: border),
        boxShadow: style == PillStyle.outline
            ? null
            : [
                BoxShadow(
                  color: bg.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: dense ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

/// White pill with calendar icon — "Wed, Jul 22 2024"
class DatePill extends StatelessWidget {
  final DateTime date;
  final VoidCallback? onTap;

  const DatePill({super.key, required this.date, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AttendanceRadius.pill),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month_rounded, size: 17, color: AttendanceColors.accent),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                DateFormat('EEE, MMM d yyyy').format(date),
                key: ValueKey(DateFormat('yMd').format(date)),
                style: const TextStyle(
                  color: AttendanceColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceSectionHeading extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;
  final Widget? trailingWidget;
  final bool onDark;

  const AttendanceSectionHeading({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailing,
    this.trailingWidget,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AttendanceTypography.sectionTitle.copyWith(
              color: onDark ? Colors.white : AttendanceColors.text,
            ),
          ),
        ),
        ?trailingWidget,
        if (trailing != null)
          Pressable(
            onTap: onTrailing,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Text(
                trailing!,
                style: const TextStyle(
                  color: AttendanceColors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small rounded "⋮" button used on Overview cards
class MoreDotsButton extends StatelessWidget {
  final VoidCallback? onTap;
  const MoreDotsButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.85,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: AttendanceColors.border),
        ),
        child: const Icon(Icons.more_vert_rounded, size: 16, color: AttendanceColors.text),
      ),
    );
  }
}

class AttendancePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool shine;
  final EdgeInsetsGeometry padding;

  const AttendancePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.shine = true,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AttendanceColors.ink;
    final fg = foregroundColor ?? Colors.white;
    final enabled = onPressed != null && !loading;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: enabled ? bg : bg.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AttendanceRadius.pill),
        boxShadow: [
          if (enabled)
            BoxShadow(
              color: bg.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), child: child),
        ),
        child: Row(
          key: ValueKey('$label-$loading'),
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading) ...[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
              ),
              const SizedBox(width: 10),
            ] else if (icon != null) ...[
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AttendanceTypography.buttonLabel.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );

    if (shine && enabled) {
      content = ShineSweep(
        borderRadius: BorderRadius.circular(AttendanceRadius.pill),
        child: content,
      );
    }

    return Pressable(onTap: enabled ? onPressed : null, scale: 0.97, child: content);
  }
}

/// White rounded card container with a soft shadow
class AttendanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AttendanceColors.card,
    this.radius = AttendanceRadius.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14142B).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, child: box);
  }
}

/// Bottom-sheet scaffold used for menus/options
Future<T?> showAttendanceSheet<T>({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  String? subtitle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AttendanceColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: AttendanceTypography.sectionTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: AttendanceTypography.caption),
            ],
            const SizedBox(height: 16),
            for (var i = 0; i < children.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 40 * i),
                offset: const Offset(0, 16),
                child: children[i],
              ),
          ],
        ),
      ),
    ),
  );
}

/// Row tile used inside [showAttendanceSheet]
class SheetActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? tint;
  final Widget? trailing;

  const SheetActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AttendanceColors.accent;
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AttendanceColors.cardInner,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              size: 40,
              background: color.withValues(alpha: 0.12),
              foreground: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AttendanceTypography.cardTitle.copyWith(fontSize: 14)),
                  if (subtitle != null)
                    Text(subtitle!, style: AttendanceTypography.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded, color: AttendanceColors.textMuted),
          ],
        ),
      ),
    );
  }
}

void showAttendanceSnack(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Color color = AttendanceColors.ink,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

// =============================================================================
// Face-scan glyph (corner brackets + face) used in nav & buttons
// =============================================================================
class FaceScanGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const FaceScanGlyph({super.key, this.size = 22, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _FaceGlyphPainter(color));
  }
}

class _FaceGlyphPainter extends CustomPainter {
  final Color color;
  _FaceGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.09
      ..strokeCap = StrokeCap.round;
    final w = s.width, h = s.height, l = w * 0.28, r = w * 0.18;

    // Corner brackets
    Path corner(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(b.dx, b.dy, c.dx, c.dy);
    canvas.drawPath(corner(Offset(0, l), Offset.zero, Offset(l, 0)), p);
    canvas.drawPath(corner(Offset(w - l, 0), Offset(w, 0), Offset(w, l)), p);
    canvas.drawPath(corner(Offset(0, h - l), Offset(0, h), Offset(l, h)), p);
    canvas.drawPath(corner(Offset(w - l, h), Offset(w, h), Offset(w, h - l)), p);

    // Face: eyes + smile
    final dot = Paint()..color = color;
    canvas.drawCircle(Offset(w * 0.37, h * 0.42), w * 0.055, dot);
    canvas.drawCircle(Offset(w * 0.63, h * 0.42), w * 0.055, dot);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w / 2, h * 0.56), width: r * 2.2, height: r * 1.6),
      0.25,
      math.pi - 0.5,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceGlyphPainter old) => old.color != color;
}

// =============================================================================
// Floating frosted navigation bar (5 round buttons + sliding indigo indicator)
// =============================================================================
class AttendanceBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AttendanceBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _icons = <IconData?>[
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    null, // face scan glyph
    Icons.event_note_rounded,
    Icons.person_rounded,
  ];
  static const _labels = ['Home', 'History', 'Scan Face', 'Leave', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AttendanceRadius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C).withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(AttendanceRadius.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final slot = c.maxWidth / _icons.length;
                  const size = 52.0;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 520),
                        curve: Curves.easeOutBack,
                        left: slot * currentIndex + (slot - size) / 2,
                        top: (c.maxHeight - size) / 2,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF5B5FF0), AttendanceColors.accentDeep],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AttendanceColors.accent.withValues(alpha: 0.55),
                                blurRadius: 18,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(_icons.length, (i) {
                          final selected = i == currentIndex;
                          return Expanded(
                            child: Tooltip(
                              message: _labels[i],
                              child: Pressable(
                                onTap: () => onTap(i),
                                scale: 0.82,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: size,
                                    height: size,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? Colors.transparent
                                          : Colors.white.withValues(alpha: 0.09),
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: selected ? 1.12 : 1.0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOutBack,
                                        child: _icons[i] == null
                                            ? FaceScanGlyph(
                                                size: 22,
                                                color: Colors.white.withValues(alpha: 0.92),
                                              )
                                            : Icon(
                                                _icons[i],
                                                size: 22,
                                                color: selected
                                                    ? Colors.white
                                                    : Colors.white.withValues(alpha: 0.7),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
