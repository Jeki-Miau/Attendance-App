import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_store.dart';
import '../../services/local_face_detector.dart';
import '../../services/shift_rules.dart';
import '../../utils/face_detection/google_ml_kit.dart';
import '../attendance_design.dart';
import '../widgets/attendance_shared_widgets.dart';
import '../widgets/motion.dart';

enum AttendanceAction { checkIn, checkOut, breakAction, overtime }

class AttendScreen extends StatefulWidget {
  final AttendanceAction action;

  const AttendScreen({super.key, this.action = AttendanceAction.checkIn});

  @override
  State<AttendScreen> createState() => _AttendScreenState();
}

class _AttendScreenState extends State<AttendScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  late AttendanceAction _currentAction;

  // === Animation Controllers ===
  late final AnimationController _scanBeamController;
  late final AnimationController _failShakeController;

  bool _cameraReady = false;
  bool _cameraLoading = true;
  bool _cameraInitializationInProgress = false;
  bool _cameraPermissionDenied = false;
  bool _isVerifying = false;
  bool _faceDetected = false;
  bool _faceVerified = false;
  bool _scanFailed = false;
  bool _isDetecting = false;
  bool _isSubmitting = false;

  String _locationName = 'Main Office - Entrance Gate';
  String _capturedPhotoBase64 = '';

  @override
  void initState() {
    super.initState();
    _currentAction = widget.action;
    WidgetsBinding.instance.addObserver(this);

    _scanBeamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _failShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
          minFaceSize: 0.15,
        ),
      );
    }

    _initializeCamera();
    _loadAccurateLocationName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanBeamController.dispose();
    _failShakeController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final controller = _cameraController;
      if (controller == null) return;
      _cameraController = null;
      if (mounted) {
        setState(() {
          _cameraReady = false;
          _faceDetected = false;
          _faceVerified = false;
        });
      }
      controller.stopImageStream();
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed &&
        mounted &&
        _cameraController == null) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraInitializationInProgress) return;
    _cameraInitializationInProgress = true;

    if (mounted) {
      setState(() {
        _cameraLoading = true;
        _cameraPermissionDenied = false;
        _scanFailed = false;
        _faceDetected = false;
        _faceVerified = false;
      });
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraLoading = false;
          _cameraReady = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      await _startLiveDetection(controller);
      setState(() {
        _cameraLoading = false;
        _cameraReady = true;
        _faceVerified = false;
        _scanFailed = false;
      });
    } on CameraException catch (error) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraReady = false;
        _cameraPermissionDenied =
            error.code == 'CameraAccessDenied' ||
            error.code == 'CameraAccessDeniedWithoutPrompt';
      });
    } catch (_) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _cameraLoading = false;
        _cameraReady = false;
      });
    } finally {
      _cameraInitializationInProgress = false;
    }
  }

  Future<void> _startLiveDetection(CameraController controller) async {
    if (_faceDetector == null || kIsWeb) return;
    try {
      await controller.startImageStream(_processCameraImage);
    } catch (_) {}
  }

  /// Deteksi wajah realtime di perangkat mobile (Android/iOS)
  Future<void> _processCameraImage(CameraImage image) async {
    final controller = _cameraController;
    if (_isDetecting || _isVerifying) return;
    if (controller == null || !controller.value.isStreamingImages) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    final detector = _faceDetector;
    if (detector == null) return;

    _isDetecting = true;
    try {
      InputImageFormat? format =
          InputImageFormatValue.fromRawValue(image.format.raw);
      if (Platform.isAndroid) format = InputImageFormat.nv21;
      if (Platform.isIOS) format = InputImageFormat.bgra8888;
      if (format == null) return;

      final rotation = InputImageRotationValue.fromRawValue(
        controller.description.sensorOrientation,
      );
      if (rotation == null) return;

      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await detector.processImage(inputImage);
      final detected = faces.isNotEmpty;
      if (!mounted || _isVerifying) return;
      if (detected == _faceDetected) return;
      setState(() {
        _faceDetected = detected;
        if (!detected) {
          _faceVerified = false;
        }
        if (detected) _scanFailed = false;
      });
    } catch (_) {
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _loadAccurateLocationName() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String placeName = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final street = p.street?.trim() ?? '';
          final subLocality = p.subLocality?.trim() ?? '';
          final locality = p.locality?.trim() ?? '';
          final parts = <String>[];
          if (street.isNotEmpty && !street.contains('Unnamed')) {
            parts.add(street);
          } else if (subLocality.isNotEmpty) {
            parts.add(subLocality);
          }
          if (locality.isNotEmpty && !parts.contains(locality)) {
            parts.add(locality);
          }
          placeName = parts.isNotEmpty ? parts.join(', ') : (p.name ?? '');
        }
      } catch (_) {}

      if (!mounted) return;
      if (placeName.isNotEmpty) {
        setState(() => _locationName = placeName);
      }
    } catch (_) {}
  }

  void _triggerScanFailure({
    String modalTitle = 'Scan Tidak Berhasil',
    String modalMessage =
        'Wajah tidak terdeteksi di depan kamera. Pastikan wajah Anda terlihat jelas di dalam bingkai pemindai lalu coba scan kembali.',
  }) {
    if (!mounted) return;
    setState(() {
      _faceDetected = false;
      _faceVerified = false;
      _scanFailed = true;
    });
    _failShakeController.forward(from: 0);
    _showNoFaceModal(
      title: modalTitle,
      message: modalMessage,
    );
  }

  /// Proses Scan Wajah 100% lokal (tanpa API key eksternal):
  /// - Android/iOS: Google ML Kit FaceDetector + fallback LocalFaceDetector
  /// - Web/Desktop: LocalFaceDetector (analisis piksel citra kamera)
  /// Apabila wajah tidak terdeteksi, scan dinyatakan TIDAK BERHASIL.
  Future<bool> _scanFace() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      await _initializeCamera();
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _triggerScanFailure(
          modalMessage:
              'Kamera belum aktif atau izin kamera ditolak, sehingga wajah tidak dapat dipindai.',
        );
        return false;
      }
    }

    final activeController = _cameraController!;

    try {
      setState(() {
        _isVerifying = true;
        _scanFailed = false;
        _faceVerified = false;
      });

      if (!kIsWeb && activeController.value.isStreamingImages) {
        try {
          await activeController.stopImageStream();
        } catch (_) {}
      }

      final xFile = await activeController.takePicture();
      final bytes = await xFile.readAsBytes();

      bool detected = false;
      String failureReason =
          'Wajah tidak terdeteksi di depan kamera. Pastikan wajah Anda berada di tengah bingkai kamera.';

      if (!kIsWeb && _faceDetector != null) {
        try {
          final temp = File(xFile.path);
          final inputImage = InputImage.fromFilePath(xFile.path);
          final faces = await _faceDetector!.processImage(inputImage);
          if (await temp.exists()) await temp.delete();
          detected = faces.isNotEmpty;
        } catch (_) {
          final localRes = await LocalFaceDetector.detectFromBytes(bytes);
          detected = localRes.faceDetected;
          failureReason = localRes.reason;
        }
      } else {
        final localRes = await LocalFaceDetector.detectFromBytes(bytes);
        detected = localRes.faceDetected;
        failureReason = localRes.reason;
      }

      if (!mounted) return false;

      if (!detected) {
        _triggerScanFailure(modalMessage: failureReason);
        return false;
      }

      setState(() {
        _faceDetected = true;
        _faceVerified = true;
        _scanFailed = false;
        _capturedPhotoBase64 = base64Encode(bytes);
      });

      showAttendanceSnack(
        context,
        'Scan wajah berhasil! Wajah terdeteksi.',
        icon: Icons.check_circle_rounded,
        color: AttendanceColors.green,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      _triggerScanFailure(
        modalMessage:
            'Tidak dapat mengambil gambar dari kamera. Pastikan kamera aktif dan coba lagi.',
      );
      return false;
    } finally {
      if (mounted &&
          !kIsWeb &&
          _cameraController == activeController &&
          _faceDetector != null &&
          !activeController.value.isStreamingImages) {
        unawaited(_startLiveDetection(activeController));
      }
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  /// Saat tombol utama ("Check in" / "Check out" / dll.) ditekan:
  /// Selalu memindai keberadaan wajah terlebih dahulu apabila belum terdeteksi.
  /// Jika wajah tidak terdeteksi, scan dinyatakan TIDAK BERHASIL dan absensi dibatalkan.
  Future<void> _handleCheckInButton() async {
    if (_isVerifying || _isSubmitting) return;
    if (!_faceVerified) {
      final scanSucceeded = await _scanFace();
      if (!scanSucceeded || !mounted) {
        return;
      }
    }
    await _submitAttendance();
  }

  String get _actionTitle {
    return switch (_currentAction) {
      AttendanceAction.checkIn => 'Check in',
      AttendanceAction.checkOut => 'Check out',
      AttendanceAction.breakAction => 'Break',
      AttendanceAction.overtime => 'Overtime',
    };
  }

  String get _actionType {
    return switch (_currentAction) {
      AttendanceAction.checkIn => 'check_in',
      AttendanceAction.checkOut => 'check_out',
      AttendanceAction.breakAction => 'break',
      AttendanceAction.overtime => 'overtime',
    };
  }

  IconData get _actionIcon {
    return switch (_currentAction) {
      AttendanceAction.checkIn => Icons.south_west_rounded,
      AttendanceAction.checkOut => Icons.north_east_rounded,
      AttendanceAction.breakAction => Icons.timer_outlined,
      AttendanceAction.overtime => Icons.date_range_rounded,
    };
  }

  Future<void> _submitAttendance() async {
    if (!_faceVerified) {
      _triggerScanFailure();
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final eval = ShiftRules.evaluate(_actionType, now);
    final record = AttendanceRecord(
      id: now.microsecondsSinceEpoch.toString(),
      title: _actionTitle,
      status: eval.label,
      type: _actionType,
      createdAt: now,
      location: _locationName,
      note: 'Wajah terdeteksi pada kamera',
      biometricConfidence: 1.0,
      verificationBadge: 'Face Detected',
      photoBase64: _capturedPhotoBase64,
    );

    try {
      final result = await AttendanceStore.addWithResult(record);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result == AttendanceAddResult.saved) {
        _showSuccessDialog(now);
      } else {
        final msg = switch (result) {
          AttendanceAddResult.duplicate =>
            '$_actionTitle sudah tercatat untuk hari ini.',
          AttendanceAddResult.requiresCheckIn =>
            'Silakan lakukan Check in terlebih dahulu.',
          AttendanceAddResult.alreadyCheckedOut =>
            'Anda sudah melakukan Check out hari ini.',
          AttendanceAddResult.checkOutRequired =>
            'Silakan Check out terlebih dahulu sebelum Check in baru.',
          AttendanceAddResult.saved => '',
        };
        showAttendanceSnack(
          context,
          msg,
          icon: Icons.info_outline_rounded,
          color: AttendanceColors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAttendanceSnack(
        context,
        'Gagal menyimpan absensi: $e',
        icon: Icons.error_outline_rounded,
        color: AttendanceColors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7B7C85),
      body: Stack(
        children: [
          // === Atmospheric Slate Gradient Background (sesuai gambar referensi) ===
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6B6C75),
                    Color(0xFF8E9099),
                    Color(0xFFBCBDC6),
                    Color(0xFFDADCE3),
                  ],
                  stops: [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // === Top Bar: Back (<) | "Scan Face" | Options (⋮) ===
                FadeSlideIn(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFrostedCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Scan Face',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        _buildFrostedCircleButton(
                          icon: Icons.more_vert_rounded,
                          onTap: _showScanModeSheet,
                        ),
                      ],
                    ),
                  ),
                ),

                // === Clean Center Face Scanner Frame (seperti gambar referensi) ===
                Expanded(
                  flex: 5,
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    scaleFrom: 0.9,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: AnimatedBuilder(
                            animation: _failShakeController,
                            builder: (context, child) {
                              final shakeOffset = math.sin(
                                    _failShakeController.value * math.pi * 6,
                                  ) *
                                  (1.0 - _failShakeController.value) *
                                  12.0;
                              return Transform.translate(
                                offset: Offset(shakeOffset, 0),
                                child: child,
                              );
                            },
                            child: _buildFaceScannerFrame(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // === 3 Floating Controls Row: Camera Button | Current Time Pill | Bolt Scan Button ===
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 2, 26, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left round white button: Refresh Camera
                        Pressable(
                          onTap: _initializeCamera,
                          scale: 0.88,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.image_outlined,
                              color: AttendanceColors.accent,
                              size: 21,
                            ),
                          ),
                        ),

                        // Center "Current Time / 08:55 AM" pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AttendanceRadius.pill),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const IconBadge(
                                icon: Icons.access_time_filled_rounded,
                                size: 34,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Current Time',
                                    style: TextStyle(
                                      color: AttendanceColors.secondaryText,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  StreamBuilder<int>(
                                    stream: Stream.periodic(
                                      const Duration(seconds: 1),
                                      (i) => i,
                                    ),
                                    builder: (context, _) {
                                      return Text(
                                        DateFormat('hh:mm a')
                                            .format(DateTime.now()),
                                        style: const TextStyle(
                                          color: AttendanceColors.text,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Right round white button: Trigger Face Scan
                        Pressable(
                          onTap: _isVerifying ? null : () => _scanFace(),
                          scale: 0.88,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _faceVerified
                                  ? AttendanceColors.green
                                  : (_scanFailed
                                      ? AttendanceColors.red
                                      : Colors.white),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              _faceVerified
                                  ? Icons.check_rounded
                                  : (_scanFailed
                                      ? Icons.close_rounded
                                      : Icons.bolt_rounded),
                              color: (_faceVerified || _scanFailed)
                                  ? Colors.white
                                  : AttendanceColors.text,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // === Bottom White Sheet with Map, Radar Pulse & Check-in Button ===
                Expanded(
                  flex: 5,
                  child: FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    offset: const Offset(0, 40),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 28,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            // Map Card with Floating "Current Location" Pill & Concentric Radar Pulse
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(
                                    color: AttendanceColors.border,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(26),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      const Positioned.fill(
                                        child: VectorCityMapCanvas(seed: 7),
                                      ),

                                      const Positioned(
                                        bottom: 6,
                                        child: RadarPulseIndicator(size: 130),
                                      ),

                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        right: 12,
                                        child: Pressable(
                                          onTap: _loadAccurateLocationName,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 11,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.07),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                const IconBadge(
                                                  icon:
                                                      Icons.location_on_rounded,
                                                  size: 40,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Current Location',
                                                        style: TextStyle(
                                                          color: AttendanceColors
                                                              .secondaryText,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _locationName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color:
                                                              AttendanceColors
                                                                  .text,
                                                          fontSize: 14.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: -0.2,
                                                        ),
                                                      ),
                                                    ],
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

                            const SizedBox(height: 12),

                            // Primary Action Button ("Check in")
                            AttendancePrimaryButton(
                              label: _isVerifying
                                  ? 'Scanning Face...'
                                  : (_isSubmitting
                                      ? 'Saving $_actionTitle...'
                                      : _actionTitle),
                              loading: _isVerifying || _isSubmitting,
                              backgroundColor: _faceVerified
                                  ? AttendanceColors.green
                                  : (_scanFailed
                                      ? AttendanceColors.red
                                      : AttendanceColors.ink),
                              foregroundColor: Colors.white,
                              onPressed: _handleCheckInButton,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  /// Bingkai kamera bersih seperti gambar referensi:
  /// - 4 siku sudut putih membulat di luar
  /// - Kotak putih membulat berisi kamera bersih (tanpa pill teks yang menutupi wajah)
  /// - Satu garis laser scan horizontal yang bergerak halus
  Widget _buildFaceScannerFrame() {
    return AnimatedBuilder(
      animation: _scanBeamController,
      builder: (context, _) {
        return CustomPaint(
          foregroundPainter: _FaceScannerBracketAndBeamPainter(
            beamProgress: _scanBeamController.value,
            verified: _faceVerified,
            faceDetected: _faceDetected,
            scanFailed: _scanFailed,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _scanFailed
                        ? AttendanceColors.red.withValues(alpha: 0.28)
                        : (_faceVerified
                            ? AttendanceColors.green.withValues(alpha: 0.28)
                            : Colors.black.withValues(alpha: 0.16)),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: GestureDetector(
                  onTap: _isVerifying ? null : () => _scanFace(),
                  child: _cameraReady && _cameraController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width:
                                _cameraController!.value.previewSize?.height ??
                                    300,
                            height:
                                _cameraController!.value.previewSize?.width ??
                                    300,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      : _CameraStageFallback(
                          loading: _cameraLoading,
                          permissionDenied: _cameraPermissionDenied,
                          onRetry: _initializeCamera,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showScanModeSheet() {
    showAttendanceSheet(
      context: context,
      title: 'Pilih Mode Absensi',
      subtitle: 'Scan wajah akan mendeteksi keberadaan wajah Anda di kamera',
      children: [
        for (final mode in AttendanceAction.values)
          SheetActionTile(
            icon: switch (mode) {
              AttendanceAction.checkIn => Icons.south_west_rounded,
              AttendanceAction.checkOut => Icons.north_east_rounded,
              AttendanceAction.breakAction => Icons.timer_outlined,
              AttendanceAction.overtime => Icons.date_range_rounded,
            },
            title: switch (mode) {
              AttendanceAction.checkIn => 'Mode: Check in',
              AttendanceAction.checkOut => 'Mode: Check out',
              AttendanceAction.breakAction => 'Mode: Break',
              AttendanceAction.overtime => 'Mode: Overtime',
            },
            onTap: () {
              setState(() => _currentAction = mode);
              Navigator.pop(context);
            },
            trailing: _currentAction == mode
                ? const StatusPill(label: 'Aktif', style: PillStyle.indigo)
                : null,
          ),
      ],
    );
  }

  void _showNoFaceModal({
    String title = 'Scan Tidak Berhasil',
    String message =
        'Wajah tidak terdeteksi di depan kamera. Absensi tidak dapat dilakukan apabila wajah tidak terdeteksi.',
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.84, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.86,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AttendanceColors.red.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.face_retouching_off_rounded,
                    color: AttendanceColors.red,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AttendanceColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AttendanceColors.secondaryText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                AttendancePrimaryButton(
                  label: 'Scan Ulang',
                  backgroundColor: AttendanceColors.red,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(DateTime timestamp) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved =
            CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, anim1, anim2) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.86,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AttendanceColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$_actionTitle Berhasil!',
                  style: const TextStyle(
                    color: AttendanceColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('EEEE, d MMM yyyy • hh:mm:ss a').format(timestamp),
                  textAlign: TextAlign.center,
                  style: AttendanceTypography.caption,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AttendanceColors.cardInner,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Icon(_actionIcon,
                          color: AttendanceColors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const StatusPill(
                        label: 'Wajah Terdeteksi',
                        style: PillStyle.green,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AttendancePrimaryButton(
                  label: 'Selesai',
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Custom Painter: Hanya 4 Outer Rounded Corner Brackets + Garis Laser Scan
// Bersih persis seperti gambar referensi (tanpa jaring mesh, tanpa oval, tanpa teks)
// =============================================================================
class _FaceScannerBracketAndBeamPainter extends CustomPainter {
  final double beamProgress;
  final bool verified;
  final bool faceDetected;
  final bool scanFailed;

  const _FaceScannerBracketAndBeamPainter({
    required this.beamProgress,
    required this.verified,
    required this.faceDetected,
    required this.scanFailed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final Color bracketColor = scanFailed
        ? AttendanceColors.red
        : (verified
            ? AttendanceColors.green
            : (faceDetected ? const Color(0xFF565AF0) : Colors.white));

    // 1. Empat siku sudut membulat di luar bingkai (seperti gambar referensi)
    final bracketPaint = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    const inset = 2.0;
    final arm = w * 0.19;
    const r = 28.0;

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

    // 2. Garis laser scan horizontal beserta gradasi lembutnya (seperti gambar referensi)
    final beamY = h * (0.20 + 0.60 * beamProgress);
    const beamLeft = 8.0;
    final beamRight = w - 8.0;
    final trailHeight = h * 0.22;

    final beamColor = scanFailed
        ? AttendanceColors.red
        : (verified ? AttendanceColors.green : const Color(0xFF565AF0));

    final trailRect = Rect.fromLTWH(
      beamLeft + 6,
      beamY,
      beamRight - beamLeft - 12,
      trailHeight.clamp(0.0, h - beamY - 14),
    );
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          beamColor.withValues(alpha: 0.30),
          beamColor.withValues(alpha: 0.08),
          beamColor.withValues(alpha: 0.0),
        ],
      ).createShader(trailRect);
    canvas.drawRect(trailRect, trailPaint);

    final beamLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          beamColor.withValues(alpha: 0.1),
          beamColor,
          Colors.white,
          beamColor,
          beamColor.withValues(alpha: 0.1),
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(
          Rect.fromLTWH(beamLeft, beamY - 2, beamRight - beamLeft, 4))
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(beamLeft, beamY),
      Offset(beamRight, beamY),
      beamLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceScannerBracketAndBeamPainter old) {
    return old.beamProgress != beamProgress ||
        old.verified != verified ||
        old.faceDetected != faceDetected ||
        old.scanFailed != scanFailed;
  }
}

class _CameraStageFallback extends StatelessWidget {
  final bool loading;
  final bool permissionDenied;
  final VoidCallback onRetry;

  const _CameraStageFallback({
    required this.loading,
    required this.permissionDenied,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF141624),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              loading
                  ? Icons.videocam_outlined
                  : Icons.videocam_off_outlined,
              size: 36,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 8),
            Text(
              loading
                  ? 'Membuka Kamera...'
                  : (permissionDenied
                      ? 'Izin Kamera Ditolak'
                      : 'Kamera Tidak Aktif'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!loading) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius:
                        BorderRadius.circular(AttendanceRadius.pill),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
