import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  late Future<LaporanPage> _future;
  String? _filterStatus;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _api.getLaporans(status: _filterStatus, page: _page);
    });
  }

  void _gantiFilter(String? value) {
    _filterStatus = value;
    _page = 1; // kembali ke halaman 1 tiap ganti filter
    _reload();
  }

  void _gantiHalaman(int page) {
    _page = page;
    _reload();
  }

  // Alert konfirmasi logout, dipakai untuk user maupun admin.
  // Pesannya disesuaikan sedikit tergantung peran yang sedang login.
  Future<void> _konfirmasiLogout(bool isAdmin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar Akun'),
        content: Text(isAdmin
            ? 'Yakin ingin keluar dari akun admin?'
            : 'Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () => _konfirmasiLogout(isAdmin),
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
              child: FutureBuilder<LaporanPage>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Gagal memuat data: ${snapshot.error}'));
                  }
                  final result = snapshot.data;
                  final data = result?.items ?? [];
                  if (data.isEmpty) {
                    return const Center(child: Text('Belum ada laporan.'));
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, i) {
                            final laporan = data[i];
                            return LaporanCard(
                              laporan: laporan,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LaporanDetailScreen(
                                          laporanId: laporan.id)),
                                );
                                _reload();
                              },
                            );
                          },
                        ),
                      ),
                      if (result != null && result.lastPage > 1)
                        _paginationBar(result),
                    ],
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
        onSelected: (_) => _gantiFilter(value),
      ),
    );
  }

  // Kontrol navigasi halaman (5 laporan per halaman, diatur di server).
  Widget _paginationBar(LaporanPage result) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Halaman sebelumnya',
            onPressed: result.currentPage > 1
                ? () => _gantiHalaman(result.currentPage - 1)
                : null,
          ),
          Text('Halaman ${result.currentPage} dari ${result.lastPage}'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Halaman berikutnya',
            onPressed: result.currentPage < result.lastPage
                ? () => _gantiHalaman(result.currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }
}
