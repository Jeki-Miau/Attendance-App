import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Hasil deteksi keberadaan wajah secara lokal (on-device / in-browser)
/// tanpa memerlukan API key eksternal.
class LocalFaceDetectionResult {
  final bool faceDetected;
  final String reason;

  const LocalFaceDetectionResult({
    required this.faceDetected,
    required this.reason,
  });
}

/// Detektor keberadaan wajah berbasis analisis citra (YCbCr skin-tone cluster,
/// proporsi geometri wajah di area tengah, serta kontras fitur internal mata/alis/mulut).
/// Berjalan 100% lokal di Flutter Web maupun Mobile/Desktop tanpa API key.
class LocalFaceDetector {
  LocalFaceDetector._();

  static Future<LocalFaceDetectionResult> detectFromBytes(
    Uint8List imageBytes,
  ) async {
    if (imageBytes.isEmpty) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Gambar kamera kosong.',
      );
    }

    ui.Codec? codec;
    ui.Image? image;
    try {
      codec = await ui.instantiateImageCodec(
        imageBytes,
        targetWidth: 120,
        targetHeight: 120,
      );
      final frame = await codec.getNextFrame();
      image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return const LocalFaceDetectionResult(
          faceDetected: false,
          reason: 'Gagal membaca piksel gambar dari kamera.',
        );
      }

      return _analyzeRgbaFrame(
        byteData.buffer.asUint8List(),
        image.width,
        image.height,
      );
    } catch (_) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Gagal memproses gambar dari kamera.',
      );
    } finally {
      image?.dispose();
      codec?.dispose();
    }
  }

  static LocalFaceDetectionResult _analyzeRgbaFrame(
    Uint8List rgba,
    int width,
    int height,
  ) {
    final totalPixels = width * height;
    if (totalPixels == 0 || rgba.length < totalPixels * 4) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Frame kamera tidak valid.',
      );
    }

    // 1. Hitung luminansi rata-rata & simpangan baku seluruh frame
    double sumY = 0;
    double sumSqY = 0;
    final lum = Float32List(totalPixels);

    for (var i = 0; i < totalPixels; i++) {
      final idx = i * 4;
      final r = rgba[idx].toDouble();
      final g = rgba[idx + 1].toDouble();
      final b = rgba[idx + 2].toDouble();
      final y = 0.299 * r + 0.587 * g + 0.114 * b;
      lum[i] = y;
      sumY += y;
      sumSqY += y * y;
    }

    final meanY = sumY / totalPixels;
    final varianceY = math.max(0.0, (sumSqY / totalPixels) - (meanY * meanY));
    final stdY = math.sqrt(varianceY);

    // Kamera tertutup / gelap gulita
    if (meanY < 20.0) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Kamera terlalu gelap atau tertutup. Wajah tidak terdeteksi.',
      );
    }

    // Tembok polos / langit-langit / layar putih / kamera tertutup benda satu warna
    if (stdY < 13.0) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Wajah tidak terdeteksi di depan kamera.',
      );
    }

    // 2. Deteksi piksel warna kulit manusia (YCbCr + RGB) di area tengah bingkai
    final xMin = (width * 0.14).round();
    final xMax = (width * 0.86).round();
    final yMin = (height * 0.10).round();
    final yMax = (height * 0.90).round();

    int centerTotal = 0;
    int skinCount = 0;
    int minSkinX = width;
    int maxSkinX = 0;
    int minSkinY = height;
    int maxSkinY = 0;

    for (var y = yMin; y < yMax; y++) {
      for (var x = xMin; x < xMax; x++) {
        centerTotal++;
        final idx = (y * width + x) * 4;
        final r = rgba[idx].toDouble();
        final g = rgba[idx + 1].toDouble();
        final b = rgba[idx + 2].toDouble();

        if (_isHumanSkinPixel(r, g, b)) {
          skinCount++;
          if (x < minSkinX) minSkinX = x;
          if (x > maxSkinX) maxSkinX = x;
          if (y < minSkinY) minSkinY = y;
          if (y > maxSkinY) maxSkinY = y;
        }
      }
    }

    final skinRatio = centerTotal > 0 ? skinCount / centerTotal : 0.0;

    // Jika terlalu sedikit warna wajah di area tengah (< 9%), berarti tidak ada wajah
    if (skinRatio < 0.09) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Wajah tidak terdeteksi di dalam bingkai kamera.',
      );
    }

    // Jika hampir seluruh area (> 86%) adalah warna seragam (mis. jari menutup lensa / tembok krem)
    if (skinRatio > 0.86) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason:
            'Wajah tidak terlihat jelas (kamera terlalu dekat atau tertutup).',
      );
    }

    // 3. Cek ukuran & proporsi bounding box area wajah
    final boxW = maxSkinX - minSkinX;
    final boxH = maxSkinY - minSkinY;
    if (boxW < width * 0.16 || boxH < height * 0.18) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Wajah terlalu jauh atau tidak terdeteksi di bingkai.',
      );
    }

    // 4. Cek kontras fitur wajah internal (mata, alis, hidung, mulut)
    // Wajah asli memiliki variasi kontras & tepi horizontal di dalam bounding box wajah,
    // berbeda dengan permukaan datar seperti meja kayu, tembok krem, atau telapak tangan polos.
    double faceSumY = 0;
    double faceSumSqY = 0;
    double gradSum = 0;
    int facePixels = 0;

    for (var y = minSkinY + 1; y < maxSkinY - 1; y++) {
      for (var x = minSkinX + 1; x < maxSkinX - 1; x++) {
        final i = y * width + x;
        final py = lum[i];
        faceSumY += py;
        faceSumSqY += py * py;

        final gx = (lum[i + 1] - lum[i - 1]).abs();
        final gy = (lum[i + width] - lum[i - width]).abs();
        gradSum += (gx + gy) * 0.5;
        facePixels++;
      }
    }

    if (facePixels < 40) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Wajah tidak terdeteksi di depan kamera.',
      );
    }

    final faceMeanY = faceSumY / facePixels;
    final faceStdY = math.sqrt(
      math.max(0.0, (faceSumSqY / facePixels) - (faceMeanY * faceMeanY)),
    );
    final meanGrad = gradSum / facePixels;

    // Permukaan polos tanpa detail mata/alis/mulut akan memiliki gradien & std rendah
    if (faceStdY < 10.5 || meanGrad < 4.2) {
      return const LocalFaceDetectionResult(
        faceDetected: false,
        reason: 'Fitur wajah tidak terdeteksi. Arahkan wajah ke kamera.',
      );
    }

    return const LocalFaceDetectionResult(
      faceDetected: true,
      reason: 'Wajah terdeteksi.',
    );
  }

  /// Model deteksi kulit manusia lintas tone kulit (YCbCr + aturan dominansi hangat RGB)
  static bool _isHumanSkinPixel(double r, double g, double b) {
    final y = 0.299 * r + 0.587 * g + 0.114 * b;
    if (y < 32.0 || y > 242.0) return false;

    final cb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b;

    final inYCbCrCluster =
        cb >= 76.0 && cb <= 134.0 && cr >= 131.0 && cr <= 178.0;
    final inRgbWarmth =
        r > 45.0 && g > 28.0 && b > 15.0 && r >= g - 4.0 && (r - b) >= 10.0;

    return inYCbCrCluster && inRgbWarmth;
  }
}
