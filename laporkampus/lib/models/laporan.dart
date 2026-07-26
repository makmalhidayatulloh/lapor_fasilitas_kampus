class Laporan {
  final int id;
  final String judul;
  final String deskripsi;
  final String? fotoUrl;
  final String? lokasiText;
  final double? latitude;
  final double? longitude;
  final String status; // pending | proses | selesai
  final String? catatanAdmin;
  final String kategoriNama;
  final int kategoriId;
  final String pelaporNama;
  final DateTime createdAt;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.fotoUrl,
    required this.lokasiText,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.catatanAdmin,
    required this.kategoriNama,
    required this.kategoriId,
    required this.pelaporNama,
    required this.createdAt,
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    return Laporan(
      id: json['id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
      fotoUrl: json['foto_url'],
      lokasiText: json['lokasi_text'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      status: json['status'],
      catatanAdmin: json['catatan_admin'],
      kategoriNama: json['kategori']['nama'],
      kategoriId: json['kategori']['id'],
      pelaporNama: json['pelapor']['nama'],
      // Server (Laravel) mengirim created_at dalam UTC (config timezone=UTC).
      // Tanpa .toLocal(), DateTime.parse akan menampilkan jam UTC apa adanya,
      // sehingga waktu yang tampil di layar meleset dari jam asli perangkat
      // (mis. selisih 7 jam untuk WIB). .toLocal() mengubahnya ke waktu
      // perangkat pengguna supaya "waktu realtime" akurat.
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
