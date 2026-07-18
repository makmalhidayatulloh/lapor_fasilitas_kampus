import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class LokasiResult {
  final double latitude;
  final double longitude;
  LokasiResult(this.latitude, this.longitude);
}

class MediaException implements Exception {
  final String message;
  MediaException(this.message);
  @override
  String toString() => message;
}

class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Membuka kamera langsung (bukan galeri) untuk memotret fasilitas rusak.
  Future<File?> ambilFotoDariKamera() async {
    final XFile? shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (shot == null) return null;
    return File(shot.path);
  }

  /// Mengambil koordinat GPS saat ini secara otomatis.
  Future<LokasiResult> ambilLokasiSaatIni() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw MediaException(
          'Layanan lokasi (GPS) tidak aktif. Mohon aktifkan GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw MediaException(
            'Izin lokasi ditolak. Aplikasi butuh akses lokasi untuk bukti laporan.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw MediaException(
          'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LokasiResult(position.latitude, position.longitude);
  }
}
