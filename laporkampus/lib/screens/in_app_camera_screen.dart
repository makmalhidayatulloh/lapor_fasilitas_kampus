import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Kamera yang tampil DI DALAM aplikasi (tidak pindah ke app Kamera bawaan HP).
/// Dibuat khusus untuk mengatasi masalah di HP dengan RAM terbatas (seperti
/// Oppo A5 2020) yang sering meng-kill aplikasi saat berpindah ke app lain.
class InAppCameraScreen extends StatefulWidget {
  const InAppCameraScreen({super.key});

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() =>
            _error = 'Tidak ada kamera yang terdeteksi di perangkat ini.');
        return;
      }

      // Pakai kamera belakang (back camera) sebagai default
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Resolusi medium supaya ringan di memori tapi tetap cukup jelas untuk bukti laporan
      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initFuture = _controller!.initialize();
      await _initFuture;

      if (mounted) setState(() {});
    } catch (e) {
      setState(() => _error = 'Gagal membuka kamera: $e');
    }
  }

  Future<void> _ambilFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile shot = await _controller!.takePicture();
      if (mounted) Navigator.pop(context, File(shot.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal memotret: $e')));
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto Bukti Kerusakan'),
      ),
      // SizedBox.expand memaksa body benar-benar mengisi seluruh area yang
      // tersedia di bawah AppBar (lebar & tinggi penuh), sehingga Stack di
      // dalamnya selalu mendapat constraint yang pasti (tight), bukan cuma
      // sebesar kontennya.
      body: SizedBox.expand(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center),
        ),
      );
    }

    if (_controller == null || _initFuture == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }

        // PENTING: fit: StackFit.expand membuat Stack SELALU mengambil
        // seluruh ruang yang tersedia (bukan menyusut sebesar tombol
        // shutter). Sebelumnya, karena tombol shutter tidak dibungkus
        // Positioned, Stack ikut menyusut sebesar tombol itu sendiri
        // -> preview kamera jadi kecil di pojok & ketutup tombol.
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _buildFullscreenPreview()),
            // Tombol shutter dibungkus Positioned (bukan alignment biasa)
            // supaya tidak ikut memengaruhi ukuran Stack.
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: GestureDetector(
                  onTap: _ambilFoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: Colors.grey.shade400, width: 4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Menampilkan CameraPreview secara fullscreen tanpa gambar jadi gepeng
  /// (distorsi). CameraPreview punya rasio aspek sensor sendiri (mis. 4:3)
  /// yang biasanya beda dengan rasio layar HP (mis. 9:19.5). Kalau langsung
  /// di-Positioned.fill tanpa perlakuan khusus, gambar preview akan
  /// dipaksa/di-stretch sampai gepeng. Widget ini melakukan efek
  /// "cover" (seperti BoxFit.cover / CSS object-fit: cover): preview
  /// tetap penuh 1 layar tapi rasio aslinya dipertahankan (sedikit
  /// terpotong di sisi, bukan gepeng).
  Widget _buildFullscreenPreview() {
    final controller = _controller!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        var scale = size.aspectRatio * controller.value.aspectRatio;
        if (scale < 1) scale = 1 / scale;

        // CATATAN PENTING: CameraPreview SUDAH membungkus dirinya sendiri
        // dengan AspectRatio yang benar (termasuk membalik rasionya untuk
        // orientasi portrait). Membungkusnya lagi dengan AspectRatio di
        // sini (seperti versi sebelumnya) menyebabkan "double AspectRatio"
        // yang saling tabrakan -> preview jadi terkotak kecil di tengah
        // dengan bar hitam atas-bawah, dan terlihat seperti "gepeng".
        // Solusinya: cukup taruh CameraPreview polos di dalam Center, lalu
        // scale seluruhnya (bukan cuma boks aspect ratio-nya) agar menutupi
        // layar penuh tanpa mengubah rasio gambar sama sekali.
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }
}