import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../attendance_design.dart';
import '../widgets/motion.dart';
import 'jeki_creator_photo_data.dart';

class _SocialChannel {
  final String platform;
  final String handle;
  final String url;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SocialChannel({
    required this.platform,
    required this.handle,
    required this.url,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const _jekiSocials = <_SocialChannel>[
  _SocialChannel(
    platform: 'Instagram',
    handle: '@jeki.png',
    url: 'https://instagram.com/jeki.artist',
    subtitle: 'Visual Art, Competition ig & Daily Creative',
    icon: Icons.camera_alt_rounded,
    color: Color(0xFFE1306C),
  ),
  _SocialChannel(
    platform: 'Behance',
    handle: 'behance.net/dzakyabdillah',
    url: 'https://behance.net/dzakyabdillah',
    subtitle: 'UI/UX Case Studies & Art Direction Portfolio',
    icon: Icons.palette_rounded,
    color: Color(0xFF0057FF),
  ),
  _SocialChannel(
    platform: 'GitHub',
    handle: 'github.com/Jeki-Miau',
    url: 'https://github.com/Jeki-Miau',
    subtitle: 'Software Projects, Motion UI & Creative Code',
    icon: Icons.code_rounded,
    color: Color(0xFF24292E),
  ),
  _SocialChannel(
    platform: 'Email & Kolaborasi',
    handle: 'dzakyabdh@gmail.com',
    url: 'mailto:dzakyabdh@gmail.com',
    subtitle: 'Open for Freelance, Art Direction & UI/UX Project',
    icon: Icons.alternate_email_rounded,
    color: AttendanceColors.orange,
  ),
];

/// Halaman "About Us & Creator Profile"
/// Menampilkan Muhammad Dzaky Abdillah a.k.a JEKI ("Designer as an Artist")
class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  int _kudosCount = 1284;
  bool _hasGivenKudos = false;

  void _giveKudos() {
    setState(() {
      _kudosCount++;
      _hasGivenKudos = true;
    });
    showAttendanceSnack(
      context,
      'Thank you for your support! 🔥 (#$_kudosCount)',
      icon: Icons.local_fire_department_rounded,
      color: AttendanceColors.orange,
    );
  }

  Future<void> _copySocial(_SocialChannel item) async {
    await Clipboard.setData(ClipboardData(text: item.url));
    if (!mounted) return;
    showAttendanceSnack(
      context,
      '${item.platform} (${item.handle}) berhasil disalin ke Clipboard!',
      icon: Icons.check_circle_rounded,
      color: AttendanceColors.green,
    );
  }

  void _showFullPhotoDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Creator Photo',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.90,
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AttendanceColors.ink,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFFFFEA00).withValues(alpha: 0.75),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFEA00).withValues(alpha: 0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: const AspectRatio(
                    aspectRatio: 1.0,
                    child: JekiCreatorImage(
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Muhammad Dzaky Abdillah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEA00),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'a.k.a JEKI • "Designer as an Artist"',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AttendancePrimaryButton(
                  label: 'Tutup Preview',
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AttendanceColors.ink,
      body: AttendancePageFrame(
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Kembali',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEA00).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(
                        AttendanceRadius.pill,
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFEA00).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulseDot(color: Color(0xFFFFEA00), size: 7),
                        SizedBox(width: 7),
                        Text(
                          'CREATOR SPOTLIGHT',
                          style: TextStyle(
                            color: Color(0xFFFFEA00),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.flip_camera_android_rounded,
                    tooltip: 'Flip Artist ID Card',
                    onTap: () => setState(() => _isFlipped = !_isFlipped),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'About This Project & Creator',
                style: AttendanceTypography.headerSubtitle,
              ),
              const SizedBox(height: 4),
              const Text('About Me', style: AttendanceTypography.headerTitle),
            ],
          ),
        ),
        sheet: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. HERO ARTIST / CREATOR 3D FLIP CARD ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: GestureDetector(
                onTap: () => setState(() => _isFlipped = !_isFlipped),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _isFlipped ? math.pi : 0),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutBack,
                  builder: (context, angle, _) {
                    final showBack = angle > (math.pi / 2);
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: showBack
                          ? Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildCreatorBackPassCard(),
                            )
                          : _buildCreatorFrontCard(),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // === 2. QUICK APPRECIATION & PORTFOLIO ACTION BAR ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Pressable(
                      onTap: _giveKudos,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _hasGivenKudos
                                ? const [Color(0xFFFF7A2F), Color(0xFFE8432E)]
                                : const [
                                    AttendanceColors.accent,
                                    AttendanceColors.accentDeep,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AttendanceColors.accent.withValues(
                                alpha: 0.24,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Give me an applause ($_kudosCount)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Pressable(
                      onTap: _showFullPhotoDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AttendanceColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              color: AttendanceColors.text,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Lihat Foto',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AttendanceColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // === 3. CREATIVE MANIFESTO: "DESIGNER AS AN ARTIST" ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 240),
              child: AttendanceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEA00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.black,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"What can i say?"',
                                style: AttendanceTypography.cardTitle,
                              ),
                              Text(
                                'Muhammad Dzaky Abdillah • Creative Vision',
                                style: AttendanceTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Bagi saya, desain bukan sekadar menyusun tata letak atau komponen antarmuka—melainkan medium ekspresi seni yang hidup. Setiap transisi, tipografi, dan detail visual dirancang agar pengguna merasakan pengalaman yang berkarakter, ekspresif, dan tak membosankan.',
                      style: TextStyle(
                        color: AttendanceColors.secondaryText,
                        fontSize: 13,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats Row
                    Row(
                      children: [
                        _buildCreatorMetric('24+', 'UI/UX Artworks'),
                        const SizedBox(width: 8),
                        _buildCreatorMetric('100%', 'Custom Motion'),
                        const SizedBox(width: 8),
                        _buildCreatorMetric('IDN', 'Tech & Design'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // === 4. SOCIAL MEDIA & DIRECT CONNECT HUB ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Media Sosial & Portofolio',
                    style: AttendanceTypography.sectionTitle,
                  ),
                  StatusPill(
                    label: 'Ketuk untuk Salin',
                    style: PillStyle.indigo,
                    dense: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            for (var i = 0; i < _jekiSocials.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 340 + i * 55),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSocialCard(_jekiSocials[i]),
                ),
              ),

            const SizedBox(height: 14),

            // === 5. SKILL & CRAFT MASTERY ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 520),
              child: AttendanceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keahlian & Spesialisasi Kreatif',
                      style: AttendanceTypography.sectionTitle,
                    ),
                    const SizedBox(height: 14),
                    _buildSkillRow(
                      'Visual Art, Poster & Graphic Direction',
                      0.99,
                      const Color(0xFFE1306C),
                    ),
                    const SizedBox(height: 12),
                    _buildSkillRow(
                      'UI/UX Design System & Bento Architecture',
                      0.97,
                      AttendanceColors.accent,
                    ),
                    const SizedBox(height: 12),
                    _buildSkillRow(
                      'Flutter Cross-Platform & Micro-Animations',
                      0.95,
                      AttendanceColors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildSkillRow(
                      'Creative Branding & Typography',
                      0.96,
                      AttendanceColors.orange,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // === 6. ABOUT THIS PROJECT (ATTENDANCE APP) ===
            FadeSlideIn(
              delay: const Duration(milliseconds: 580),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AttendanceColors.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        IconBadge(
                          icon: Icons.rocket_launch_rounded,
                          size: 38,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tentang Project Attendance App',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Crafted by Muhammad Dzaky Abdillah (JEKI)',
                                style: TextStyle(
                                  color: AttendanceColors.accentSoft,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aplikasi presensi generasi baru yang memadukan deteksi wajah (Face Detection), peta kota vektor dengan radar lokasi aktif, penghitung jam kerja realtime (Live Working Hours), gamifikasi heatmap bulanan, serta pencetakan slip digital.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu Depan: Menampilkan Foto Street-Art JEKI + Nama + Tagline "Designer as an Artist"
  Widget _buildCreatorFrontCard() {
    return Container(
      decoration: BoxDecoration(
        color: AttendanceColors.ink,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFEA00).withValues(alpha: 0.65),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AttendanceColors.ink.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Artwork Container
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: Stack(
              children: [
                const AspectRatio(
                  aspectRatio: 1.05,
                  child: JekiCreatorImage(
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // Subtle bottom gradient fade into card footer
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AttendanceColors.ink.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                  ),
                ),
                // Top-Right Flip Hint Pill
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: const Color(0xFFFFEA00).withValues(alpha: 0.7),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 13,
                          color: Color(0xFFFFEA00),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Ketuk untuk Flip ID',
                          style: TextStyle(
                            color: Colors.white,
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
          ),

          // Creator Name, Alias & "Designer as an Artist" Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEA00),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'a.k.a JEKI',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AttendanceColors.accent,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        '"Designer as an Artist"',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Muhammad Dzaky Abdillah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Creative Illustrator • Visual Artist • Software Developer',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Belakang (Saat Di-flip): Artist Studio Pass & Signature Quote
  Widget _buildCreatorBackPassCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141629), Color(0xFF0B0B12)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFFFEA00).withValues(alpha: 0.75),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const JekiCreatorImage(
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OFFICIAL CREATOR PASS',
                      style: TextStyle(
                        color: Color(0xFFFFEA00),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Muhammad Dzaky Abdillah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'a.k.a "JEKI" • Designer as an Artist',
                      style: TextStyle(
                        color: AttendanceColors.accentSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Jangan pernah  tunjukkan mereka apa yang kau impikan, namun tebarkan hasil yang  kau ciptakan"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '— Muhammad Dzaky Abdillah (JEKI)',
                  style: TextStyle(
                    color: Color(0xFFFFEA00),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STUDIO / CARRIER',
                    style: TextStyle(
                      color: AttendanceColors.textMuted,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Freelancer • IT & Illustrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Ketuk untuk Balik Kartu ↺',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorMetric(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AttendanceColors.cardInner,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AttendanceColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AttendanceColors.secondaryText,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialCard(_SocialChannel item) {
    return Pressable(
      onTap: () => _copySocial(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AttendanceColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.platform,
                        style: const TextStyle(
                          color: AttendanceColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.handle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AttendanceColors.secondaryText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AttendanceColors.cardInner,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AttendanceColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(String title, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AttendanceColors.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, val, _) {
              return LinearProgressIndicator(
                value: val,
                minHeight: 7,
                backgroundColor: AttendanceColors.cardInner,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}
