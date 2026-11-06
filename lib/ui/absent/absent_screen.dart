import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_store.dart';
import '../attendance_design.dart';
import '../widgets/motion.dart';

class AbsentScreen extends StatelessWidget {
  const AbsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AttendanceColors.ink,
      body: AbsentContent(),
    );
  }
}

class AbsentContent extends StatefulWidget {
  const AbsentContent({super.key});

  @override
  State<AbsentContent> createState() => _AbsentContentState();
}

class _CategoryData {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color accent;
  final int quotaDays;

  const _CategoryData({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.accent,
    required this.quotaDays,
  });
}

class _AbsentContentState extends State<AbsentContent> {
  final TextEditingController _reasonController = TextEditingController();
  late DateTime _selectedDate;
  String _selectedType = 'Sick Leave';
  bool _isSubmitting = false;
  List<AttendanceRecord> _leaveHistory = const [];

  static const List<_CategoryData> _categories = [
    _CategoryData(
      title: 'Sick Leave',
      subtitle: 'Medical rest or clinic recovery',
      tag: 'Medical',
      icon: Icons.healing_rounded,
      accent: AttendanceColors.accent,
      quotaDays: 12,
    ),
    _CategoryData(
      title: 'Annual Leave',
      subtitle: 'Paid personal holiday & family time',
      tag: 'Paid Off',
      icon: Icons.beach_access_rounded,
      accent: AttendanceColors.orange,
      quotaDays: 14,
    ),
    _CategoryData(
      title: 'Work From Home',
      subtitle: 'Remote sprint delivery & deep focus',
      tag: 'Remote',
      icon: Icons.laptop_mac_rounded,
      accent: AttendanceColors.green,
      quotaDays: 24,
    ),
    _CategoryData(
      title: 'Emergency Permit',
      subtitle: 'Urgent family or personal matters',
      tag: 'Priority',
      icon: Icons.bolt_rounded,
      accent: AttendanceColors.red,
      quotaDays: 5,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    AttendanceStore.revision.addListener(_loadLeaves);
    _loadLeaves();
  }

  @override
  void dispose() {
    AttendanceStore.revision.removeListener(_loadLeaves);
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaves() async {
    final all = await AttendanceStore.load();
    if (!mounted) return;
    setState(() {
      _leaveHistory = all.where((r) => r.type == 'leave').toList();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitLeave() async {
    if (_isSubmitting) return;
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      showAttendanceSnack(
        context,
        'Please enter a short reason for your absence request.',
        icon: Icons.warning_amber_rounded,
        color: AttendanceColors.red,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final profile = await AttendanceStore.loadProfile();
    final formattedDate = DateFormat('dd MMM yyyy').format(_selectedDate);

    final record = AttendanceRecord(
      id: now.microsecondsSinceEpoch.toString(),
      title: '$_selectedType ($formattedDate)',
      status: 'Approved',
      type: 'leave',
      createdAt: now,
      location: 'Remote • ${profile.name}',
      note: reason,
      biometricConfidence: 1.0,
      verificationBadge: 'HR Verified',
    );

    try {
      await AttendanceStore.add(record);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _reasonController.clear();
      });
      showAttendanceSnack(
        context,
        '$_selectedType request submitted & logged!',
        icon: Icons.verified_rounded,
        color: AttendanceColors.green,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAttendanceSnack(
        context,
        'Could not record leave request: $e',
        icon: Icons.error_outline_rounded,
        color: AttendanceColors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AttendancePageFrame(
      onRefresh: _loadLeaves,
      header: AttendanceHeader(
        subtitle: 'Submit leave or remote work permit',
        title: 'Request Absence',
        actions: [
          CircleIconButton(
            icon: Icons.event_available_rounded,
            tooltip: 'Pick Effective Date',
            onTap: _pickDate,
          ),
        ],
      ),
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Top Row: Leave Balance Overview + Date Pill ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Leave Category',
                  style: AttendanceTypography.sectionTitle,
                ),
                DatePill(
                  date: _selectedDate,
                  onTap: _pickDate,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // === 2x2 Bento Grid of Leave Categories (matches Overview style) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.24,
              ),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = cat.title == _selectedType;
                return Pressable(
                  onTap: () => setState(() => _selectedType = cat.title),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AttendanceColors.ink : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? AttendanceColors.ink.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(
                              icon: cat.icon,
                              size: 34,
                              background: selected
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : AttendanceColors.lavender,
                              foreground: selected
                                  ? Colors.white
                                  : AttendanceColors.accent,
                            ),
                            const Spacer(),
                            StatusPill(
                              label: cat.tag,
                              style: selected
                                  ? PillStyle.indigo
                                  : PillStyle.orange,
                              dense: true,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          cat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : AttendanceColors.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.quotaDays} Days Quota',
                          style: TextStyle(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.65)
                                : AttendanceColors.secondaryText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // === Reason & Justification Card ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: AttendanceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(icon: Icons.edit_note_rounded, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reason & Handover Notes',
                              style: AttendanceTypography.cardTitle,
                            ),
                            Text(
                              'Selected: $_selectedType • ${DateFormat('EEE, MMM d yyyy').format(_selectedDate)}',
                              style: AttendanceTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AttendanceColors.cardInner,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Describe your leave reason, clinic note, or WFH sprint tasks...',
                        hintStyle: TextStyle(
                          color: AttendanceColors.textMuted,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick template chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in [
                        'Sprint WFH & Code Review',
                        'Medical Checkup & Rest',
                        'Family Annual Holiday',
                      ])
                        Pressable(
                          onTap: () =>
                              setState(() => _reasonController.text = preset),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AttendanceColors.lavender,
                              borderRadius: BorderRadius.circular(
                                AttendanceRadius.pill,
                              ),
                            ),
                            child: Text(
                              '+ $preset',
                              style: const TextStyle(
                                color: AttendanceColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AttendancePrimaryButton(
                    label: _isSubmitting
                        ? 'Submitting Request...'
                        : 'Submit $_selectedType',
                    loading: _isSubmitting,
                    icon: Icons.send_rounded,
                    onPressed: _submitLeave,
                  ),
                ],
              ),
            ),
          ),

          if (_leaveHistory.isNotEmpty) ...[
            const SizedBox(height: 22),
            const FadeSlideIn(
              delay: Duration(milliseconds: 320),
              child: Text(
                'Submitted Permits',
                style: AttendanceTypography.sectionTitle,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in _leaveHistory.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AttendanceCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const IconBadge(
                        icon: Icons.description_outlined,
                        size: 38,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AttendanceTypography.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.note.isEmpty
                                  ? item.location
                                  : item.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AttendanceTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      StatusPill(
                        label: item.status,
                        style: PillStyle.orange,
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
