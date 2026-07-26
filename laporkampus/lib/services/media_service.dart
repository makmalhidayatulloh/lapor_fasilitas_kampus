import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
}
