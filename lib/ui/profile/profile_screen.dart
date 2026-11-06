import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/attendance_store.dart';
import '../about/about_us_screen.dart';
import '../about/jeki_creator_photo_data.dart';
import '../attendance_design.dart';
import '../welcome/welcome_auth_screen.dart';
import '../widgets/attendance_shared_widgets.dart';
import '../widgets/motion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  String _photoBase64 = '';
  bool _isLoading = true;
  bool _isSaving = false;
  int _recordCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _roleController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await AttendanceStore.loadProfile();
    final records = await AttendanceStore.load();
    if (!mounted) return;
    setState(() {
      _nameController.text = profile.name;
      _idController.text = profile.employeeId;
      _roleController.text = profile.role;
      _deptController.text = profile.department;
      _photoBase64 = profile.photoBase64;
      _recordCount = records.length;
      _isLoading = false;
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          _photoBase64 = base64Encode(bytes);
        });
        showAttendanceSnack(
          context,
          'Profile photo updated!',
          color: AttendanceColors.green,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAttendanceSnack(
        context,
        'Camera not available for profile photo: $e',
        icon: Icons.info_outline_rounded,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final profile = UserProfile(
      name: _nameController.text.trim().isEmpty
          ? 'Chandra Pratama'
          : _nameController.text.trim(),
      employeeId: _idController.text.trim().isEmpty
          ? '8152'
          : _idController.text.trim(),
      role: _roleController.text.trim().isEmpty
          ? 'Senior Product Designer'
          : _roleController.text.trim(),
      department: _deptController.text.trim().isEmpty
          ? 'Design & Tech'
          : _deptController.text.trim(),
      photoBase64: _photoBase64,
    );

    await AttendanceStore.saveProfile(profile);

    if (!mounted) return;
    setState(() => _isSaving = false);
    showAttendanceSnack(
      context,
      'Profile saved & synced across workspace!',
      color: AttendanceColors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AttendancePageFrame(
      onRefresh: _loadProfile,
      header: AttendanceHeader(
        subtitle: 'Biometric identity & employee pass',
        title: 'Profile & Settings',
        actions: [
          CircleIconButton(
            icon: Icons.camera_alt_rounded,
            tooltip: 'Capture Profile Photo',
            onTap: _pickPhoto,
          ),
          CircleIconButton(
            icon: Icons.check_rounded,
            tooltip: 'Save Profile',
            onTap: _saveProfile,
          ),
        ],
      ),
      sheet: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Employee Biometric Identity Card ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AttendanceColors.ink,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AttendanceColors.ink.withValues(alpha: 0.16),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        UserAvatarBadge(
                          photoBase64: _photoBase64,
                          size: 68,
                          onTap: _pickPhoto,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _nameController.text.isEmpty
                                          ? 'Chandra Pratama'
                                          : _nameController.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const StatusPill(
                                    label: 'Verified',
                                    style: PillStyle.indigo,
                                    dense: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_roleController.text} • ID #${_idController.text}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.68),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const PulseDot(
                                    color: AttendanceColors.green,
                                    size: 7,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_recordCount Face-Verified Checkpoints',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
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

                const SizedBox(height: 20),

                // === Editable Employee Details Card ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: AttendanceCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Employee Details',
                          style: AttendanceTypography.sectionTitle,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          label: 'Full Name (Greeting Name)',
                          controller: _nameController,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Employee Badge ID',
                          controller: _idController,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Job Title / Role',
                          controller: _roleController,
                          icon: Icons.work_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          label: 'Department',
                          controller: _deptController,
                          icon: Icons.apartment_rounded,
                        ),
                        const SizedBox(height: 18),
                        AttendancePrimaryButton(
                          label: _isSaving ? 'Saving...' : 'Save Profile',
                          loading: _isSaving,
                          icon: Icons.check_circle_outline_rounded,
                          onPressed: _saveProfile,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // === About Us & Creator Card (Muhammad Dzaky Abdillah a.k.a JEKI) ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: Pressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const AboutUsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AttendanceColors.ink,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFFFEA00).withValues(alpha: 0.65),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: const JekiCreatorImage(
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEA00),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: const Text(
                                        'ABOUT ME • JEKI',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        '"Designer as an Artist"',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AttendanceColors.accentSoft,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'About Me — Muhammad Dzaky Abdillah',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'About This Project, Creator & Media Sosial',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.68),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFFFEA00),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Reset Demo Data Card ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 280),
                  child: AttendanceCard(
                    onTap: () async {
                      await AttendanceStore.clearAll();
                      await _loadProfile();
                      if (context.mounted) {
                        showAttendanceSnack(
                          context,
                          'Demo records & default profile restored!',
                          icon: Icons.restore_rounded,
                        );
                      }
                    },
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        IconBadge(
                          icon: Icons.restore_rounded,
                          size: 40,
                          background: Color(0xFFFFEFE5),
                          foreground: AttendanceColors.orange,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset Demo Attendance Data',
                                style: AttendanceTypography.cardTitle,
                              ),
                              Text(
                                'Restore fresh sample week & clear today’s session',
                                style: AttendanceTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AttendanceColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Replay Welcoming / Introducing Page Card ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 330),
                  child: AttendanceCard(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        SmoothPageRoute(
                          page: const WelcomeAuthScreen(startAtLogin: false),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        IconBadge(
                          icon: Icons.auto_awesome_rounded,
                          size: 40,
                          background: AttendanceColors.accentSurface,
                          foreground: AttendanceColors.accent,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tampilkan Welcoming Page',
                                style: AttendanceTypography.cardTitle,
                              ),
                              Text(
                                'Lihat kembali halaman perkenalan fitur project',
                                style: AttendanceTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AttendanceColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === Sign Out / Switch Employee Account Card ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 380),
                  child: AttendanceCard(
                    onTap: () async {
                      await AttendanceStore.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        SmoothPageRoute(
                          page: const WelcomeAuthScreen(startAtLogin: true),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        IconBadge(
                          icon: Icons.logout_rounded,
                          size: 40,
                          background: Color(0xFFFFEAE9),
                          foreground: AttendanceColors.red,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Keluar Akun (Sign Out)',
                                style: AttendanceTypography.cardTitle,
                              ),
                              Text(
                                'Kembali ke halaman Login & ganti akun karyawan',
                                style: AttendanceTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AttendanceColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
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
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: AttendanceColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 19, color: AttendanceColors.accent),
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
