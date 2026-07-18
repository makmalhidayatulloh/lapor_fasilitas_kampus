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
      body: _buildBody(),
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

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: GestureDetector(
                onTap: _ambilFoto,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400, width: 4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
