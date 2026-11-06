import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_store.dart';
import '../attendance_design.dart';
import '../widgets/attendance_advanced_widgets.dart';
import '../widgets/attendance_shared_widgets.dart';
import '../widgets/motion.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AttendanceColors.ink,
      body: AttendanceHistoryContent(),
    );
  }
}

class _ProjectTask {
  final String category;
  final String title;
  final String description;
  final int files;
  final int links;
  final int images;
  double progress;

  _ProjectTask({
    required this.category,
    required this.title,
    required this.description,
    required this.files,
    required this.links,
    required this.images,
    required this.progress,
  });
}

class AttendanceHistoryContent extends StatefulWidget {
  const AttendanceHistoryContent({super.key});

  @override
  State<AttendanceHistoryContent> createState() =>
      _AttendanceHistoryContentState();
}

class _AttendanceHistoryContentState extends State<AttendanceHistoryContent> {
  bool _loading = true;
  bool _newestFirst = true;
  String? _loadError;
  DateTime _selectedDate = DateTime.now();
  bool _filterBySelectedDayOnly = false;
  String _typeFilter = 'All';
  List<AttendanceRecord> _records = const [];

  final List<_ProjectTask> _tasks = [
    _ProjectTask(
      category: 'Design',
      title: 'Optimize Book Layout',
      description:
          'Reorganize the warehouse to improve space utilization and efficiency.',
      files: 4,
      links: 2,
      images: 6,
      progress: 0.32,
    ),
    _ProjectTask(
      category: 'Marketing',
      title: 'Audit Inventory',
      description:
          'Perform a detailed check of current inventory levels and assets.',
      files: 1,
      links: 3,
      images: 4,
      progress: 0.64,
    ),
    _ProjectTask(
      category: 'Biometrics',
      title: 'Face Mesh Calibration',
      description:
          'Fine-tune real-time facial landmark confidence thresholds.',
      files: 5,
      links: 4,
      images: 3,
      progress: 0.86,
    ),
  ];

  @override
  void initState() {
    super.initState();
    AttendanceStore.revision.addListener(_onStoreChanged);
    _loadRecords();
  }

  @override
  void dispose() {
    AttendanceStore.revision.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    _loadRecords(silent: true);
  }

  Future<void> _loadRecords({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final records = await AttendanceStore.load();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load records: $error';
        _loading = false;
      });
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _weekDays {
    // Monday-start 7-day strip centered around _selectedDate's week
    final weekday = _selectedDate.weekday; // 1 = Mon .. 7 = Sun
    final monday = _selectedDate.subtract(Duration(days: weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
  }

  List<AttendanceRecord> get _visibleRecords {
    var list = _records.where((r) {
      if (_typeFilter != 'All') {
        final matchType = switch (_typeFilter) {
          'Check in' => r.type == 'check_in',
          'Check out' => r.type == 'check_out',
          'Break' => r.type == 'break',
          'Overtime' => r.type == 'overtime',
          'Leave' => r.type == 'leave',
          _ => true,
        };
        if (!matchType) return false;
      }
      if (_filterBySelectedDayOnly) {
        return _sameDay(r.createdAt, _selectedDate);
      }
      return true;
    }).toList();

    // Prioritize records from _selectedDate at the top when not strictly filtering
    list.sort((a, b) {
      final aSelected = _sameDay(a.createdAt, _selectedDate);
      final bSelected = _sameDay(b.createdAt, _selectedDate);
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      return _newestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null && mounted) {
      setState(() => _selectedDate = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRecords;

    return AttendancePageFrame(
      onRefresh: () => _loadRecords(),
      header: AttendanceHeader(
        subtitle: 'View your attendance details',
        title: 'Attendance History',
        actions: [
          CircleIconButton(
            icon: Icons.link_rounded,
            tooltip: 'Share Attendance Summary',
            onTap: _showShareSheet,
          ),
          CircleIconButton(
            icon: Icons.more_vert_rounded,
            tooltip: 'History Options',
            onTap: _showOptionsSheet,
          ),
        ],
      ),
      sheet: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Select Date + DatePill (matches Image 1) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Date',
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

          // === Black Week Strip with sliding Indigo Pill (matches Image 1) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 190),
            child: _buildBlackWeekStrip(),
          ),

          const SizedBox(height: 18),

          // === Horizontal Project / Task Cards Carousel (matches Image 1) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 260),
            child: SizedBox(
              height: 198,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _tasks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildProjectCard(_tasks[index], index);
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // === Gamified Attendance Score, Streak Badges & Monthly Heatmap ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: AttendanceHeatmapAndScoreCard(
              records: _records,
              selectedDate: _selectedDate,
              onSelectDate: (date) {
                setState(() => _selectedDate = date);
              },
              onOpenExportSlip: () {
                showDigitalAttendanceSlipModal(context, records: _records);
              },
            ),
          ),

          const SizedBox(height: 22),

          // === Result by Date + Sort By Pill (matches Image 1) ===
          FadeSlideIn(
            delay: const Duration(milliseconds: 330),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Result by Date',
                  style: AttendanceTypography.sectionTitle,
                ),
                Pressable(
                  onTap: _showSortSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
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
                        const Icon(
                          Icons.swap_vert_rounded,
                          size: 16,
                          color: AttendanceColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _typeFilter == 'All' ? 'Sort By' : _typeFilter,
                          style: const TextStyle(
                            color: AttendanceColors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                _loadError!,
                style: const TextStyle(color: AttendanceColors.red),
              ),
            )
          else if (visible.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const IconBadge(
                    icon: Icons.calendar_today_rounded,
                    size: 46,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No logs on ${DateFormat('EEE, MMM d').format(_selectedDate)}',
                    style: AttendanceTypography.cardTitle,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap below to show all recent attendance records.',
                    style: AttendanceTypography.caption,
                  ),
                  const SizedBox(height: 14),
                  Pressable(
                    onTap: () =>
                        setState(() => _filterBySelectedDayOnly = false),
                    child: const StatusPill(
                      label: 'Show All Dates',
                      style: PillStyle.indigo,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < visible.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 360 + (i.clamp(0, 6)) * 60),
                    child: MapActivityCard(
                      record: visible[i],
                      index: i,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBlackWeekStrip() {
    final days = _weekDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AttendanceColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AttendanceColors.ink.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List.generate(days.length, (i) {
          final d = days[i];
          final selected = _sameDay(d, _selectedDate);
          final hasRecord = _records.any((r) => _sameDay(r.createdAt, d));
          return Expanded(
            child: Pressable(
              onTap: () {
                setState(() {
                  _selectedDate = d;
                });
              },
              scale: 0.9,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? AttendanceColors.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color:
                                AttendanceColors.accent.withValues(alpha: 0.45),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEE').format(d),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        fontSize: 11.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('d').format(d),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: hasRecord ? 4 : 0,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.white
                            : AttendanceColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProjectCard(_ProjectTask task, int index) {
    final pct = (task.progress * 100).round();
    return Pressable(
      onTap: () => _showTaskSheet(task),
      child: Container(
        width: 248,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF14142B).withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag pill ("Design", "Marketing")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AttendanceColors.cardInner,
                borderRadius: BorderRadius.circular(AttendanceRadius.pill),
              ),
              child: Text(
                task.category,
                style: const TextStyle(
                  color: AttendanceColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AttendanceColors.text,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AttendanceColors.secondaryText,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Metadata row: 4 Files  2 Links  6 Images
            Row(
              children: [
                const Icon(
                  Icons.folder_rounded,
                  size: 14,
                  color: AttendanceColors.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.files} Files',
                  style: const TextStyle(
                    color: AttendanceColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.link_rounded,
                  size: 14,
                  color: AttendanceColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.links} Links',
                  style: const TextStyle(
                    color: AttendanceColors.secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.image_rounded,
                  size: 14,
                  color: AttendanceColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${task.images} Images',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AttendanceColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Animated Progress Bar + "32 %"
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: task.progress),
                      duration: const Duration(milliseconds: 950),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return LinearProgressIndicator(
                          value: val,
                          minHeight: 7,
                          backgroundColor: AttendanceColors.cardInner,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AttendanceColors.accent,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CountUpText(
                  value: pct,
                  suffix: ' %',
                  style: const TextStyle(
                    color: AttendanceColors.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskSheet(_ProjectTask task) {
    showAttendanceSheet(
      context: context,
      title: task.title,
      subtitle: '${task.category} Deliverable • Tap below to update completion',
      children: [
        for (final pct in [0.32, 0.50, 0.75, 1.0])
          SheetActionTile(
            icon: pct == 1.0
                ? Icons.check_circle_rounded
                : Icons.trending_up_rounded,
            title: 'Set progress to ${(pct * 100).round()}%',
            subtitle: pct == 1.0
                ? 'Mark deliverable as completed'
                : 'Update sprint milestone progress',
            tint: pct == 1.0 ? AttendanceColors.green : AttendanceColors.accent,
            onTap: () {
              setState(() => task.progress = pct);
              Navigator.pop(context);
            },
          ),
      ],
    );
  }

  void _showSortSheet() {
    showAttendanceSheet(
      context: context,
      title: 'Sort & Filter Records',
      subtitle: 'Customize how your attendance logs are ordered',
      children: [
        SheetActionTile(
          icon: Icons.schedule_rounded,
          title: _newestFirst
              ? 'Order: Newest First (Tap to flip)'
              : 'Order: Oldest First (Tap to flip)',
          subtitle: 'Sort attendance events chronologically',
          onTap: () {
            setState(() => _newestFirst = !_newestFirst);
            Navigator.pop(context);
          },
        ),
        SheetActionTile(
          icon: Icons.filter_alt_outlined,
          title: _filterBySelectedDayOnly
              ? 'Showing: Selected Day Only'
              : 'Showing: All Recent Days',
          subtitle: 'Toggle strict single-day filter on the week strip',
          tint: AttendanceColors.orange,
          onTap: () {
            setState(
              () => _filterBySelectedDayOnly = !_filterBySelectedDayOnly,
            );
            Navigator.pop(context);
          },
        ),
        for (final f in ['All', 'Check in', 'Check out', 'Break', 'Leave'])
          SheetActionTile(
            icon: Icons.check_circle_outline_rounded,
            title: 'Filter: $f',
            onTap: () {
              setState(() => _typeFilter = f);
              Navigator.pop(context);
            },
            trailing: _typeFilter == f
                ? const StatusPill(label: 'Active', style: PillStyle.indigo)
                : null,
          ),
      ],
    );
  }

  void _showShareSheet() {
    showDigitalAttendanceSlipModal(context, records: _records);
  }

  void _showOptionsSheet() {
    showAttendanceSheet(
      context: context,
      title: 'History Options',
      subtitle: 'Manage your stored attendance logs',
      children: [
        SheetActionTile(
          icon: Icons.today_rounded,
          title: 'Jump to Today',
          subtitle: DateFormat('EEEE, MMM d yyyy').format(DateTime.now()),
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _selectedDate = DateTime.now();
              _filterBySelectedDayOnly = false;
              _typeFilter = 'All';
            });
          },
        ),
        SheetActionTile(
          icon: Icons.refresh_rounded,
          title: 'Reload Attendance Store',
          subtitle: 'Sync latest biometric logs from local storage',
          tint: AttendanceColors.green,
          onTap: () {
            Navigator.pop(context);
            _loadRecords();
          },
        ),
      ],
    );
  }
}
