import 'package:flutter/material.dart';

import '../../services/attendance_store.dart';
import '../attendance_design.dart';
import '../navigation_shell.dart';
import '../widgets/attendance_shared_widgets.dart';
import '../widgets/motion.dart';

class _DemoEmployeeAccount {
  final String name;
  final String badgeId;
  final String email;
  final String role;
  final String department;
  final String password;

  const _DemoEmployeeAccount({
    required this.name,
    required this.badgeId,
    required this.email,
    required this.role,
    required this.department,
    required this.password,
  });
}

const _demoAccounts = <_DemoEmployeeAccount>[
  _DemoEmployeeAccount(
    name: 'JEKII',
    badgeId: '8101',
    email: 'jeki@office.id',
    role: 'Designer as an Artist',
    department: 'Creative & Art Direction',
    password: 'password123',
  ),
  _DemoEmployeeAccount(
    name: 'Chandra Pratama',
    badgeId: '8152',
    email: 'chandra@office.id',
    role: 'Senior Product Designer',
    department: 'Design & Tech',
    password: 'password123',
  ),
  _DemoEmployeeAccount(
    name: 'Nadia Putri',
    badgeId: '8190',
    email: 'nadia@office.id',
    role: 'Lead Mobile Engineer',
    department: 'Engineering',
    password: 'password123',
  ),
  _DemoEmployeeAccount(
    name: 'Budi Santoso',
    badgeId: '8204',
    email: 'budi@office.id',
    role: 'Product Manager',
    department: 'Product & Strategy',
    password: 'password123',
  ),
];

/// Halaman Welcoming / Introducing Project + Login & Registrasi Karyawan
class WelcomeAuthScreen extends StatefulWidget {
  final bool startAtLogin;

  const WelcomeAuthScreen({super.key, this.startAtLogin = false});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _laserController;

  int _currentSlide = 0;
  late bool _showLoginSection;
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;
  int _selectedDemoIndex = 0;

  // Login Controllers
  final TextEditingController _identifierController = TextEditingController(
    text: 'chandra@office.id',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'password123',
  );

  // Register Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regBadgeController = TextEditingController();
  final TextEditingController _regRoleController = TextEditingController();
  final TextEditingController _regDeptController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _showLoginSection = widget.startAtLogin;
    _pageController = PageController();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _laserController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _regNameController.dispose();
    _regBadgeController.dispose();
    _regRoleController.dispose();
    _regDeptController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _selectDemoAccount(int index) {
    final acc = _demoAccounts[index];
    setState(() {
      _selectedDemoIndex = index;
      _identifierController.text = acc.email;
      _passwordController.text = acc.password;
    });
  }

  void _nextSlideOrGoToLogin() {
    if (_currentSlide < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() => _showLoginSection = true);
    }
  }

  Future<void> _submitAuth() async {
    if (_isSubmitting) return;

    if (_isRegisterMode) {
      final name = _regNameController.text.trim();
      final badge = _regBadgeController.text.trim();
      final role = _regRoleController.text.trim();
      final dept = _regDeptController.text.trim();
      final pass = _regPasswordController.text.trim();

      if (name.isEmpty || badge.isEmpty || pass.isEmpty) {
        showAttendanceSnack(
          context,
          'Mohon lengkapi Nama, ID Karyawan, dan Password.',
          icon: Icons.error_outline_rounded,
          color: AttendanceColors.red,
        );
        return;
      }

      setState(() => _isSubmitting = true);
      await Future<void>.delayed(const Duration(milliseconds: 550));

      final profile = UserProfile(
        name: name,
        employeeId: badge,
        role: role.isEmpty ? 'Product Specialist' : role,
        department: dept.isEmpty ? 'Digital Innovation' : dept,
        photoBase64: '',
      );
      await AttendanceStore.saveProfile(profile);
      await AttendanceStore.setLoggedIn(true);

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _navigateToHome(profile.name);
      return;
    }

    // Mode Login
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      showAttendanceSnack(
        context,
        'Masukkan Email / ID Karyawan dan Password terlebih dahulu.',
        icon: Icons.error_outline_rounded,
        color: AttendanceColors.red,
      );
      return;
    }

    if (password.length < 4) {
      showAttendanceSnack(
        context,
        'Password minimal 4 karakter.',
        icon: Icons.lock_outline_rounded,
        color: AttendanceColors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));

    // Cocokkan dengan demo account atau buat profil sesuai input pengguna
    final matchedDemo = _demoAccounts.where((acc) {
      final lower = identifier.toLowerCase();
      return acc.email.toLowerCase() == lower ||
          acc.badgeId == lower ||
          acc.name.toLowerCase().contains(lower);
    }).firstOrNull;

    final existingProfile = await AttendanceStore.loadProfile();
    final UserProfile activeProfile;

    if (matchedDemo != null) {
      activeProfile = UserProfile(
        name: matchedDemo.name,
        employeeId: matchedDemo.badgeId,
        role: matchedDemo.role,
        department: matchedDemo.department,
        photoBase64: existingProfile.photoBase64,
      );
    } else {
      final cleanName = identifier.contains('@')
          ? identifier
              .split('@')
              .first
              .replaceAll('.', ' ')
              .split(' ')
              .map(
                (w) => w.isEmpty
                    ? ''
                    : '${w[0].toUpperCase()}${w.substring(1)}',
              )
              .join(' ')
          : identifier;
      activeProfile = UserProfile(
        name: cleanName.isEmpty ? existingProfile.name : cleanName,
        employeeId: existingProfile.employeeId,
        role: existingProfile.role,
        department: existingProfile.department,
        photoBase64: existingProfile.photoBase64,
      );
    }

    await AttendanceStore.saveProfile(activeProfile);
    await AttendanceStore.setLoggedIn(_rememberMe);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _navigateToHome(activeProfile.name);
  }

  void _navigateToHome(String userName) {
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(page: const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AttendanceColors.darkCanvas,
      body: Stack(
        children: [
          // === Ambient Indigo & Tangerine Glow Orbs in Dark Canvas ===
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AttendanceColors.accent.withValues(alpha: 0.34),
                      AttendanceColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -80,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AttendanceColors.orange.withValues(alpha: 0.18),
                      AttendanceColors.orange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _showLoginSection
                  ? _buildLoginSection(key: const ValueKey('login-section'))
                  : _buildWelcomeIntroSection(
                      key: const ValueKey('welcome-section'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STAGE 1: WELCOMING / INTRODUCING PROJECT PAGE
  // ===========================================================================
  Widget _buildWelcomeIntroSection({Key? key}) {
    return Column(
      key: key,
      children: [
        // Top Header: Brand Pill + Skip to Login Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(AttendanceRadius.pill),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(color: AttendanceColors.green, size: 7),
                    SizedBox(width: 8),
                    Text(
                      'ATTENDANCE PRO • AI FACE SCAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () => setState(() => _showLoginSection = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AttendanceColors.accent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AttendanceRadius.pill),
                    border: Border.all(
                      color: AttendanceColors.accentSoft.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lewati ke Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Interactive Hero Slides
        Expanded(
          flex: 6,
          child: PageView(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentSlide = idx),
            children: [
              _buildSlideHeroFaceScanner(),
              _buildSlideHeroGeoRadar(),
              _buildSlideHeroAnalyticsBento(),
            ],
          ),
        ),

        // Bottom White Sheet with Project Description, Dots & CTA
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: AttendanceColors.sheetCanvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Slide Indicator Dots + Step Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(3, (index) {
                        final active = _currentSlide == index;
                        return GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: active ? 28 : 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? AttendanceColors.accent
                                  : AttendanceColors.border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        );
                      }),
                    ),
                    StatusPill(
                      label: switch (_currentSlide) {
                        0 => '01 • Face Detection',
                        1 => '02 • Live Geotagging',
                        _ => '03 • HR Analytics',
                      },
                      style: switch (_currentSlide) {
                        0 => PillStyle.indigo,
                        1 => PillStyle.orange,
                        _ => PillStyle.green,
                      },
                      dense: true,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Column(
                    key: ValueKey(_currentSlide),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (_currentSlide) {
                          0 =>
                            'Presensi Wajah Cerdas &\nCepat dalam Hitungan Detik',
                          1 =>
                            'Pelacakan Lokasi Radar &\nLive Working Hours Timer',
                          _ =>
                            'Dashboard Bento Analitik &\nPengajuan Izin Terpadu',
                        },
                        style: const TextStyle(
                          color: AttendanceColors.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        switch (_currentSlide) {
                          0 =>
                            'Project Attendance App ini menggantikan mesin absensi konvensional dengan pemindai deteksi wajah (Face Detection) langsung dari kamera perangkat Anda.',
                          1 =>
                            'Dilengkapi peta kota interaktif dengan indikator radar lokasi kantor serta penghitung jam kerja aktif (Live Working Hours) detik demi detik.',
                          _ =>
                            'Pantau riwayat Check-in, Break, Check-out, lembur (Overtime), hingga pengajuan izin/cuti/sakit dalam satu ekosistem modern.',
                        },
                        style: const TextStyle(
                          color: AttendanceColors.secondaryText,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Feature Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildMiniFeatureChip(
                        Icons.face_retouching_natural_rounded,
                        'AI Face Detection',
                      ),
                      const SizedBox(width: 8),
                      _buildMiniFeatureChip(
                        Icons.radar_rounded,
                        'GPS Radar Map',
                      ),
                      const SizedBox(width: 8),
                      _buildMiniFeatureChip(
                        Icons.timer_outlined,
                        'Live Shift Timer',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Primary CTA Button
                ShineSweep(
                  child: AttendancePrimaryButton(
                    label: _currentSlide < 2
                        ? 'Selanjutnya'
                        : 'Mulai & Masuk ke Aplikasi',
                    icon: _currentSlide < 2
                        ? Icons.arrow_forward_rounded
                        : Icons.login_rounded,
                    backgroundColor: _currentSlide < 2
                        ? AttendanceColors.ink
                        : AttendanceColors.accent,
                    onPressed: _nextSlideOrGoToLogin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AttendanceRadius.pill),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AttendanceColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AttendanceColors.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Slide 1 Hero: Animated Face Scanner Preview
  Widget _buildSlideHeroFaceScanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        child: FloatingBob(
          amplitude: 6,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: _laserController,
                builder: (context, _) {
                  return CustomPaint(
                    foregroundPainter: _IntroScannerBracketPainter(
                      progress: _laserController.value,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AttendanceColors.accent
                                  .withValues(alpha: 0.30),
                              blurRadius: 32,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(9),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1A1E3B),
                                  Color(0xFF0E1022),
                                ],
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  size: 110,
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                                const FaceScanGlyph(
                                  size: 64,
                                  color: Colors.white,
                                ),
                                Positioned(
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AttendanceColors.green
                                          .withValues(alpha: 0.90),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          'Wajah Terdeteksi ✓',
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
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Slide 2 Hero: Interactive Geo Radar Map + Live Working Hours Preview
  Widget _buildSlideHeroGeoRadar() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: FloatingBob(
          amplitude: 6,
          child: SizedBox(
            width: 330,
            height: 225,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: VectorCityMapCanvas(seed: 12),
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: RadarPulseIndicator(size: 105),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            IconBadge(
                              icon: Icons.location_on_rounded,
                              size: 32,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Verified Office Zone',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AttendanceColors.secondaryText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Main Office - Entrance Gate',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AttendanceColors.text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6),
                            StatusPill(
                              label: 'On time',
                              style: PillStyle.orange,
                              dense: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AttendanceColors.ink,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PulseDot(color: AttendanceColors.green, size: 7),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Live Work Timer • 08h : 00m : 00s',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
            ),
          ),
        ),
      ),
    );
  }

  /// Slide 3 Hero: Bento Overview & Leave Analytics Preview
  Widget _buildSlideHeroAnalyticsBento() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
        child: FloatingBob(
          amplitude: 6,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconBadge(
                                  icon: Icons.south_west_rounded,
                                  size: 30,
                                ),
                                StatusPill(
                                  label: 'On time',
                                  style: PillStyle.orange,
                                  dense: true,
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              '09:10 AM',
                              style: TextStyle(
                                color: AttendanceColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Checked in success',
                              style: TextStyle(
                                color: AttendanceColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconBadge(
                                  icon: Icons.verified_user_rounded,
                                  size: 30,
                                  background: Color(0xFFE7F9F1),
                                  foreground: AttendanceColors.green,
                                ),
                                StatusPill(
                                  label: '98.4%',
                                  style: PillStyle.green,
                                  dense: true,
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Excellent',
                              style: TextStyle(
                                color: AttendanceColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Monthly Discipline',
                              style: TextStyle(
                                color: AttendanceColors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AttendanceColors.accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pengajuan Izin, Sakit & Cuti Instan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STAGE 2: LOGIN & EMPLOYEE PORTAL SECTION
  // ===========================================================================
  Widget _buildLoginSection({Key? key}) {
    return Column(
      key: key,
      children: [
        // Top Header with Back to Welcome Intro Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Pressable(
                    onTap: () => setState(() => _showLoginSection = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AttendanceRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Intro Project',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const StatusPill(
                    label: 'Employee Portal',
                    style: PillStyle.indigo,
                    dense: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome back to workspace',
                style: AttendanceTypography.headerSubtitle,
              ),
              const SizedBox(height: 4),
              Text(
                _isRegisterMode
                    ? 'Registrasi Karyawan Baru'
                    : 'Sign In to Attendance',
                style: AttendanceTypography.headerTitle.copyWith(fontSize: 26),
              ),
            ],
          ),
        ),

        // White Rounded Sheet Form
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AttendanceColors.sheetCanvas,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(36),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Segmented Switcher: Masuk Akun vs Daftar Karyawan
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AttendanceRadius.pill),
                      border: Border.all(color: AttendanceColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildModeTab(
                            label: 'Masuk (Sign In)',
                            selected: !_isRegisterMode,
                            onTap: () =>
                                setState(() => _isRegisterMode = false),
                          ),
                        ),
                        Expanded(
                          child: _buildModeTab(
                            label: 'Daftar Karyawan',
                            selected: _isRegisterMode,
                            onTap: () =>
                                setState(() => _isRegisterMode = true),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (!_isRegisterMode) ...[
                    // === Quick Demo Employee Account Selector ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Akun Demo Cepat (1-Klik)',
                          style: TextStyle(
                            color: AttendanceColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Auto-fill',
                          style: TextStyle(
                            color:
                                AttendanceColors.accent.withValues(alpha: 0.9),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _demoAccounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final acc = _demoAccounts[index];
                          final selected = _selectedDemoIndex == index;
                          return Pressable(
                            onTap: () => _selectDemoAccount(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 215,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AttendanceColors.ink
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AttendanceColors.accent
                                      : AttendanceColors.border,
                                  width: selected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? AttendanceColors.accent
                                          : AttendanceColors.accentSurface,
                                    ),
                                    child: Center(
                                      child: Text(
                                        acc.name.substring(0, 1),
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : AttendanceColors.accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          acc.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : AttendanceColors.text,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID #${acc.badgeId} • ${acc.role}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                    .withValues(alpha: 0.68)
                                                : AttendanceColors
                                                    .secondaryText,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    // === Login Credentials Card ===
                    AttendanceCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            label: 'Email Kantor atau ID Karyawan',
                            hint: 'chandra@office.id atau 8152',
                            controller: _identifierController,
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 14),
                          _buildInputField(
                            label: 'Password / PIN Keamanan',
                            hint: 'Masukkan password',
                            controller: _passwordController,
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: AttendanceColors.secondaryText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => _rememberMe = !_rememberMe,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? AttendanceColors.accent
                                            : AttendanceColors.cardInner,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Ingat Sesi Saya',
                                      style: TextStyle(
                                        color: AttendanceColors.text,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showAttendanceSnack(
                                    context,
                                    'Gunakan password demo: password123 atau klik salah satu kartu akun di atas.',
                                    icon: Icons.key_rounded,
                                  );
                                },
                                child: const Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    color: AttendanceColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          AttendancePrimaryButton(
                            label: _isSubmitting
                                ? 'Memverifikasi Akun...'
                                : 'Masuk ke Workspace',
                            loading: _isSubmitting,
                            icon: Icons.login_rounded,
                            onPressed: _submitAuth,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // === Register Employee Card ===
                    AttendanceCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputField(
                            label: 'Nama Lengkap Karyawan',
                            hint: 'Contoh: Chandra Pratama',
                            controller: _regNameController,
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'Employee ID',
                                  hint: '8152',
                                  controller: _regBadgeController,
                                  icon: Icons.tag_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Departemen',
                                  hint: 'Design & Tech',
                                  controller: _regDeptController,
                                  icon: Icons.apartment_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            label: 'Jabatan / Role',
                            hint: 'Contoh: Senior Product Designer',
                            controller: _regRoleController,
                            icon: Icons.work_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            label: 'Password Akun',
                            hint: 'Minimal 4 karakter',
                            controller: _regPasswordController,
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 18),
                          AttendancePrimaryButton(
                            label: _isSubmitting
                                ? 'Mendaftarkan Akun...'
                                : 'Daftar & Masuk Sekarang',
                            loading: _isSubmitting,
                            icon: Icons.person_add_alt_1_rounded,
                            backgroundColor: AttendanceColors.accent,
                            onPressed: _submitAuth,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AttendanceColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(AttendanceRadius.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AttendanceColors.secondaryText,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AttendanceColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AttendanceColors.cardInner,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              color: AttendanceColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AttendanceColors.textMuted,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, size: 19, color: AttendanceColors.accent),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntroScannerBracketPainter extends CustomPainter {
  final double progress;

  const _IntroScannerBracketPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const inset = 2.0;
    final arm = w * 0.19;
    const r = 24.0;

    final tl = Path()
      ..moveTo(inset, inset + arm)
      ..lineTo(inset, inset + r)
      ..quadraticBezierTo(inset, inset, inset + r, inset)
      ..lineTo(inset + arm, inset);
    canvas.drawPath(tl, bracketPaint);

    final tr = Path()
      ..moveTo(w - inset - arm, inset)
      ..lineTo(w - inset - r, inset)
      ..quadraticBezierTo(w - inset, inset, w - inset, inset + r)
      ..lineTo(w - inset, inset + arm);
    canvas.drawPath(tr, bracketPaint);

    final bl = Path()
      ..moveTo(inset, h - inset - arm)
      ..lineTo(inset, h - inset - r)
      ..quadraticBezierTo(inset, h - inset, inset + r, h - inset)
      ..lineTo(inset + arm, h - inset);
    canvas.drawPath(bl, bracketPaint);

    final br = Path()
      ..moveTo(w - inset - arm, h - inset)
      ..lineTo(w - inset - r, h - inset)
      ..quadraticBezierTo(w - inset, h - inset, w - inset, h - inset - r)
      ..lineTo(w - inset, h - inset - arm);
    canvas.drawPath(br, bracketPaint);

    final beamY = h * (0.22 + 0.56 * progress);
    const beamLeft = 10.0;
    final beamRight = w - 10.0;

    final beamLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AttendanceColors.accent.withValues(alpha: 0.1),
          AttendanceColors.accent,
          Colors.white,
          AttendanceColors.accent,
          AttendanceColors.accent.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(
          Rect.fromLTWH(beamLeft, beamY - 2, beamRight - beamLeft, 4))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(beamLeft, beamY),
      Offset(beamRight, beamY),
      beamLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _IntroScannerBracketPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
