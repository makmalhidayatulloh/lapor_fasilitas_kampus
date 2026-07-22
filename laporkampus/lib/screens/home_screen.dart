import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/laporan.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/laporan_card.dart';
import 'create_laporan_screen.dart';
import 'laporan_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<Laporan>> _future;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _api.getLaporans(status: _filterStatus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Semua Laporan (Admin)' : 'Laporan Saya'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(null, 'Semua'),
                  _filterChip('pending', 'Menunggu'),
                  _filterChip('proses', 'Diproses'),
                  _filterChip('selesai', 'Selesai'),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Laporan>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Gagal memuat data: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Belum ada laporan.'));
                  }
                  return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, i) {
                      final laporan = data[i];
                      return LaporanCard(
                        laporan: laporan,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    LaporanDetailScreen(laporanId: laporan.id)),
                          );
                          _reload();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? null // Admin tidak membuat laporan, hanya mengelola status
          : FloatingActionButton.extended(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Lapor Kerusakan'),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CreateLaporanScreen()),
                );
                if (created == true) _reload();
              },
            ),
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          _filterStatus = value;
          _reload();
        },
      ),
    );
  }
}
