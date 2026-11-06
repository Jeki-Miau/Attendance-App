import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shift_rules.dart';

enum AttendanceAddResult {
  saved,
  duplicate,
  requiresCheckIn,
  alreadyCheckedOut,
  checkOutRequired,
}

/// User profile model supporting international enterprise standard
class UserProfile {
  final String name;
  final String employeeId;
  final String role;
  final String department;
  final String photoBase64; // Optional profile photo base64

  const UserProfile({
    required this.name,
    required this.employeeId,
    required this.role,
    required this.department,
    required this.photoBase64,
  });

  UserProfile copyWith({
    String? name,
    String? employeeId,
    String? role,
    String? department,
    String? photoBase64,
  }) {
    return UserProfile(
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      department: department ?? this.department,
      photoBase64: photoBase64 ?? this.photoBase64,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'employeeId': employeeId,
    'role': role,
    'department': department,
    'photoBase64': photoBase64,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? 'Prinz Tsabio',
      employeeId: json['employeeId']?.toString() ?? '8152',
      role: json['role']?.toString() ?? 'Lead Mobile Architect',
      department: json['department']?.toString() ?? 'Engineering',
      photoBase64: json['photoBase64']?.toString() ?? '',
    );
  }
}

/// Attendance record model with biometric match confidence and audit trail
class AttendanceRecord {
  final String id;
  final String title;
  final String status;
  final String type;
  final DateTime createdAt;
  final String location;
  final String note;
  final double biometricConfidence;
  final String? verificationBadge;
  final String photoBase64;

  const AttendanceRecord({
    required this.id,
    required this.title,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.location,
    required this.note,
    this.biometricConfidence = 0.984,
    this.verificationBadge = 'Face Detected',
    this.photoBase64 = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'location': location,
    'note': note,
    'biometricConfidence': biometricConfidence,
    'verificationBadge': verificationBadge,
    'photoBase64': photoBase64,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'];
    if (createdAtRaw is! String) {
      throw const FormatException('Record is missing its timestamp.');
    }
    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      throw const FormatException('Record timestamp is invalid.');
    }
    return AttendanceRecord(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Attendance',
      status: json['status']?.toString() ?? 'On time',
      type: json['type']?.toString() ?? 'check_in',
      createdAt: createdAt,
      location: json['location']?.toString() ?? 'Location unavailable',
      note: json['note']?.toString() ?? '',
      biometricConfidence: (json['biometricConfidence'] as num?)?.toDouble() ?? 0.98,
      verificationBadge: json['verificationBadge']?.toString() ?? 'Face Detected',
      photoBase64: json['photoBase64']?.toString() ?? '',
    );
  }
}

/// Robust Enterprise Attendance & Profile Store with SharedPreferences persistence,
/// atomic reads, fallback data safety, and validation guards.
class AttendanceStore {
  static const _key = 'attendance_records_v1';
  static const _profileKey = 'user_profile_v1';
  static const _loggedInKey = 'user_logged_in_v1';

  /// Bumped on every write so open screens can refresh themselves live.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static const _defaultProfile = UserProfile(
    name: 'Chandra Pratama',
    employeeId: '8152',
    role: 'Senior Product Designer',
    department: 'Design & Tech',
    photoBase64: '',
  );

  /// Check if user has logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  /// Set login session state
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, value);
    revision.value++;
  }

  /// Logout current user session
  static Future<void> logout() async {
    await setLoggedIn(false);
  }

  /// Load user profile with safe defaults and robust exception handling
  static Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return _defaultProfile;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
      return _defaultProfile;
    } catch (_) {
      return _defaultProfile;
    }
  }

  /// Save or update profile
  static Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    revision.value++;
  }

  /// Load attendance records
  static Future<List<AttendanceRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? <String>[];

    final records = <AttendanceRecord>[];
    for (var index = 0; index < raw.length; index++) {
      try {
        final decoded = jsonDecode(raw[index]);
        if (decoded is! Map<String, dynamic>) continue;
        records.add(AttendanceRecord.fromJson(decoded));
      } catch (_) {}
    }

    // Populate with demo records on fresh install if empty
    if (records.isEmpty) {
      records.addAll(_demoRecords(DateTime.now()));
      await _write(records);
    }

    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  /// One week of realistic demo activity (today has Check-in at 09:10 AM and
  /// Break at 11:40 AM on fresh install only if needed, or past 7 days so user
  /// can still check in today).
  static List<AttendanceRecord> _demoRecords(DateTime now) {
    const location = 'Main Office - Entrance Gate';
    const checkInOffsets = [-12, -20, 4, -6, -15, 10, -3];
    const breakOffsets = [-20, 5, 10, -5, 0, 15, 2];
    const checkOutOffsets = [5, 95, -20, 75, 10, 130, 0];
    const confidences = [0.984, 0.991, 0.972, 0.988, 0.979, 0.993, 0.981];

    final out = <AttendanceRecord>[];
    var id = 1;

    AttendanceRecord make(String type, String title, DateTime at, double conf, {String? note}) {
      final eval = ShiftRules.evaluate(type, at);
      return AttendanceRecord(
        id: 'demo-${id++}',
        title: title,
        status: eval.label,
        type: type,
        createdAt: at,
        location: location,
        note: note ?? 'Wajah terdeteksi pada kamera',
        biometricConfidence: conf,
        verificationBadge: 'Face Detected',
      );
    }

    for (var back = 7; back >= 1; back--) {
      final day = DateTime(now.year, now.month, now.day - back);
      if (day.weekday == DateTime.sunday) continue;
      final i = back % 7;
      final conf = confidences[i];

      if (back == 4) {
        out.add(AttendanceRecord(
          id: 'demo-${id++}',
          title: 'Work From Home',
          status: 'Approved',
          type: 'leave',
          createdAt: DateTime(day.year, day.month, day.day, 8, 30),
          location: 'Remote Work • Verified IP',
          note: 'Sprint planning & architecture review',
          biometricConfidence: 1.0,
          verificationBadge: 'Authorized',
        ));
        continue;
      }

      out.add(make('check_in', 'Check in',
          DateTime(day.year, day.month, day.day, 9).add(Duration(minutes: checkInOffsets[i])), conf));
      out.add(make('break', 'Break',
          DateTime(day.year, day.month, day.day, 12).add(Duration(minutes: breakOffsets[i])), conf));
      final checkOut =
          DateTime(day.year, day.month, day.day, 18).add(Duration(minutes: checkOutOffsets[i]));
      if (checkOutOffsets[i] >= 60) {
        out.add(make('overtime', 'Overtime',
            DateTime(day.year, day.month, day.day, 18, 15), conf,
            note: 'Release support • approved by lead'));
      }
      out.add(make('check_out', 'Check out', checkOut, conf));
    }
    return out;
  }

  static Future<void> _write(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = records.map((entry) => jsonEncode(entry.toJson())).toList(growable: false);
    await prefs.setStringList(_key, payload);
  }

  /// Save attendance records with atomic write
  static Future<void> save(List<AttendanceRecord> records) async {
    await _write(records);
    revision.value++;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Append new attendance record
  static Future<void> add(AttendanceRecord record) async {
    final records = await load();
    records.insert(0, record);
    await save(records);
  }

  /// Enterprise guard logic to enforce daily attendance integrity.
  static Future<AttendanceAddResult> addWithResult(AttendanceRecord record) async {
    final records = await load();
    final todayRecords =
        records.where((existing) => _isSameDay(existing.createdAt, record.createdAt)).toList();

    // Rekonstruksi keadaan sesi secara kronologis
    final events = todayRecords.map((r) {
      return MapEntry(r.createdAt.millisecondsSinceEpoch, r.type);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    bool sessionOpen = false;
    bool hadCheckIn = false;
    bool hadCheckOut = false;
    bool breakUsed = false;
    bool overtimeUsed = false;

    for (final event in events) {
      switch (event.value) {
        case 'check_in':
          sessionOpen = true;
          hadCheckIn = true;
          breakUsed = false;
          overtimeUsed = false;
        case 'check_out':
          sessionOpen = false;
          hadCheckOut = true;
          breakUsed = false;
          overtimeUsed = false;
        case 'break':
          if (sessionOpen) breakUsed = true;
        case 'overtime':
          if (sessionOpen) overtimeUsed = true;
      }
    }

    switch (record.type) {
      case 'check_in':
        if (sessionOpen || hadCheckIn) return AttendanceAddResult.duplicate;
      case 'check_out':
        if (!sessionOpen) {
          return hadCheckOut
              ? AttendanceAddResult.duplicate
              : AttendanceAddResult.requiresCheckIn;
        }
      case 'break':
        if (!sessionOpen) return AttendanceAddResult.requiresCheckIn;
        if (breakUsed) return AttendanceAddResult.duplicate;
      case 'overtime':
        if (!sessionOpen) return AttendanceAddResult.requiresCheckIn;
        if (overtimeUsed) return AttendanceAddResult.duplicate;
    }

    records.insert(0, record);
    await save(records);
    return AttendanceAddResult.saved;
  }

  /// Delete a record by ID
  static Future<void> delete(String id) async {
    final records = await load();
    records.removeWhere((record) => record.id == id);
    await save(records);
  }

  /// Reset all stored data (Development & Admin testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_profileKey);
    revision.value++;
  }
}
