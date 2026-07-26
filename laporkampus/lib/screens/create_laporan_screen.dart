import 'dart:io';
import 'package:flutter/material.dart';
import '../models/kategori.dart';
import '../services/api_service.dart';
import 'in_app_camera_screen.dart';

class CreateLaporanScreen extends StatefulWidget {
  const CreateLaporanScreen({super.key});

  @override
  State<CreateLaporanScreen> createState() => _CreateLaporanScreenState();
}

class _CreateLaporanScreenState extends State<CreateLaporanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  final _lokasiTextCtrl = TextEditingController();

  File? _foto;

  List<Kategori> _kategoriList = [];
  int? _kategoriId;
  bool _loadingKategori = true;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    try {
      final list = await _api.getKategoris();
      setState(() {
        _kategoriList = list;
        _loadingKategori = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat kategori: $e';
        _loadingKategori = false;
      });
    }
  }

  // Ambil foto dari kamera. Fitur GPS otomatis sudah dihapus dari alur ini;
  // lokasi kejadian sekarang cukup diisi manual lewat field "Nama Lokasi".
  Future<void> _ambilFoto() async {
    setState(() => _error = null);
    try {
      final file = await Navigator.push<File?>(
        context,
        MaterialPageRoute(builder: (_) => const InAppCameraScreen()),
      );
      if (file == null) return;

      setState(() => _foto = file);
    } catch (e) {
      setState(
          () => _error = e.toString().replaceFirst('MediaException: ', ''));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_foto == null) {
      setState(() => _error = 'Foto bukti kerusakan wajib diambil');
      return;
    }
    if (_kategoriId == null) {
      setState(() => _error = 'Pilih kategori kerusakan');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _api.createLaporan(
        judul: _judulCtrl.text.trim(),
        deskripsi: _deskripsiCtrl.text.trim(),
        kategoriId: _kategoriId!,
        lokasiText: _lokasiTextCtrl.text.trim().isEmpty
            ? null
            : _lokasiTextCtrl.text.trim(),
        foto: _foto!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Kerusakan Fasilitas')),
      body: _loadingKategori
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    // ==== Bagian Kamera ====
                    GestureDetector(
                      onTap: _ambilFoto,
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _foto != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_foto!,
                                    fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ketuk untuk memotret fasilitas rusak',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_foto != null)
                      TextButton.icon(
                        onPressed: _ambilFoto,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ambil ulang foto'),
                      ),

                    const SizedBox(height: 16),

                    // ==== Form Data ====
                    TextFormField(
                      controller: _judulCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Judul Laporan',
                          border: OutlineInputBorder()),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _kategoriId,
                      decoration: const InputDecoration(
                          labelText: 'Kategori Kerusakan',
                          border: OutlineInputBorder()),
                      items: _kategoriList
                          .map((k) => DropdownMenuItem(
                              value: k.id, child: Text(k.nama)))
                          .toList(),
                      onChanged: (v) => setState(() => _kategoriId = v),
                      validator: (v) => v == null ? 'Pilih kategori' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lokasiTextCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lokasi (opsional)',
                        hintText:
                            'Misal: Gedung A Lantai 2, Ruang Lab Komputer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deskripsiCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Deskripsi Kerusakan',
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Kirim Laporan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
