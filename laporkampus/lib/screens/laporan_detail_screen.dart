import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/laporan.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../widgets/status_badge.dart';

// Widget kecil untuk memuat foto laporan.
// Dipakai alih-alih Image.network langsung, karena Image.network di
// Flutter Web merender lewat tag <img> HTML biasa yang TIDAK BISA
// menyertakan header custom. Padahal header 'ngrok-skip-browser-warning'
// wajib dikirim supaya ngrok (free tier) tidak membalas dengan halaman
// peringatan HTML alih-alih file gambar aslinya.
// Solusinya: ambil bytes gambar manual pakai package http (yang bisa
// menyertakan header), lalu render pakai Image.memory.
class _LaporanFoto extends StatefulWidget {
  final String url;
  const _LaporanFoto({required this.url});

  @override
  State<_LaporanFoto> createState() => _LaporanFotoState();
}

class _LaporanFotoState extends State<_LaporanFoto> {
  late Future<Uint8List> _futureBytes;

  @override
  void initState() {
    super.initState();
    _futureBytes = _fetchBytes();
  }

  Future<Uint8List> _fetchBytes() async {
    final response = await http.get(
      Uri.parse(widget.url),
      headers: {'ngrok-skip-browser-warning': 'true'},
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat foto (status ${response.statusCode})');
    }
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _futureBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 260,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          debugPrint('GAGAL LOAD FOTO: ${snapshot.error}');
          debugPrint('URL yang dicoba: ${widget.url}');
          return Container(
            width: double.infinity,
            height: 260,
            color: Colors.grey.shade200,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Foto gagal dimuat', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class LaporanDetailScreen extends StatefulWidget {
  final int laporanId;
  const LaporanDetailScreen({super.key, required this.laporanId});

  @override
  State<LaporanDetailScreen> createState() => _LaporanDetailScreenState();
}

class _LaporanDetailScreenState extends State<LaporanDetailScreen> {
  final ApiService _api = ApiService();
  late Future<Laporan> _future;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getLaporanDetail(widget.laporanId);
  }

  void _reload() {
    setState(() {
      _future = _api.getLaporanDetail(widget.laporanId);
    });
  }

  Future<void> _ubahStatus(String status) async {
    setState(() => _updating = true);
    try {
      await _api.updateStatus(widget.laporanId, status);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal update status: $e')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _hapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: const Text('Yakin ingin menghapus laporan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteLaporan(widget.laporanId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _hapus),
        ],
      ),
      body: FutureBuilder<Laporan>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat: ${snapshot.error}'));
          }
          final laporan = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (laporan.fotoUrl != null)
                  _LaporanFoto(url: laporan.fotoUrl!),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(laporan.judul,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          StatusBadge(status: laporan.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Chip(label: Text(laporan.kategoriNama)),
                      const SizedBox(height: 16),
                      const Text('Deskripsi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(laporan.deskripsi),
                      const SizedBox(height: 16),
                      if (laporan.lokasiText != null) ...[
                        const Text('Lokasi',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(laporan.lokasiText!),
                        const SizedBox(height: 16),
                      ],
                      if (laporan.latitude != null &&
                          laporan.longitude != null) ...[
                        const Text('Koordinat GPS',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            final url = Uri.parse(
                              'https://maps.google.com/?q=${laporan.latitude},${laporan.longitude}',
                            );
                            // Catatan: gunakan package url_launcher untuk benar-benar membuka maps.
                            debugPrint('Buka maps: $url');
                          },
                          child: Text(
                            '${laporan.latitude!.toStringAsFixed(6)}, ${laporan.longitude!.toStringAsFixed(6)} (buka di Maps)',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('Pelapor: ${laporan.pelaporNama}',
                          style: const TextStyle(color: Colors.grey)),
                      Text(
                        'Dilaporkan: ${DateFormat('dd MMMM yyyy, HH:mm').format(laporan.createdAt)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (laporan.catatanAdmin != null) ...[
                        const SizedBox(height: 16),
                        const Text('Catatan Petugas',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(laporan.catatanAdmin!),
                      ],

                      // ==== Panel khusus admin untuk update status ====
                      if (isAdmin) ...[
                        const Divider(height: 32),
                        const Text('Ubah Status Perbaikan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            _statusButton(
                                'pending', 'Menunggu', laporan.status),
                            _statusButton('proses', 'Diproses', laporan.status),
                            _statusButton('selesai', 'Selesai', laporan.status),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusButton(String value, String label, String current) {
    final active = value == current;
    return ElevatedButton(
      onPressed: (_updating || active) ? null : () => _ubahStatus(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.grey.shade300 : null,
      ),
      child: Text(label),
    );
  }
}
