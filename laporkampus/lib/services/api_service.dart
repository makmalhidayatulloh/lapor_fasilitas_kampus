import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/kategori.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import 'api_config.dart';
import 'session_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  final SessionService _session = SessionService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _session.getToken();
    return {
      'Accept': 'application/json',
      // Wajib untuk ngrok free plan, agar tidak diarahkan ke halaman
      // peringatan HTML sebelum request diteruskan ke server asli.
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ================= AUTH =================

  Future<UserModel> register(String name, String email, String password,
      String passwordConfirmation) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true'
      },
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = _decode(res);
    final user = UserModel.fromJson(data['user']);
    await _session.saveSession(data['token'], user);
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true'
      },
      body: {'email': email, 'password': password},
    );

    final data = _decode(res);
    final user = UserModel.fromJson(data['user']);
    await _session.saveSession(data['token'], user);
    return user;
  }

  Future<void> logout() async {
    final headers = await _authHeaders();
    await http.post(Uri.parse('${ApiConfig.baseUrl}/logout'), headers: headers);
    await _session.clearSession();
  }

  // ================= KATEGORI =================

  Future<List<Kategori>> getKategoris() async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/kategoris'),
        headers: headers);
    final data = _decode(res) as List;
    return data.map((e) => Kategori.fromJson(e)).toList();
  }

  // ================= LAPORAN =================

  Future<List<Laporan>> getLaporans({String? status}) async {
    final headers = await _authHeaders();
    var url = '${ApiConfig.baseUrl}/laporans';
    if (status != null) url += '?status=$status';

    final res = await http.get(Uri.parse(url), headers: headers);
    final data = _decode(res);
    final List list = data['data'];
    return list.map((e) => Laporan.fromJson(e)).toList();
  }

  Future<Laporan> getLaporanDetail(int id) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/laporans/$id'),
        headers: headers);
    final data = _decode(res);
    return Laporan.fromJson(data['data']);
  }

  Future<Laporan> createLaporan({
    required String judul,
    required String deskripsi,
    required int kategoriId,
    String? lokasiText,
    double? latitude,
    double? longitude,
    required File foto,
  }) async {
    final headers = await _authHeaders();
    final request = http.MultipartRequest(
        'POST', Uri.parse('${ApiConfig.baseUrl}/laporans'));
    request.headers.addAll(headers);

    request.fields['judul'] = judul;
    request.fields['deskripsi'] = deskripsi;
    request.fields['kategori_id'] = kategoriId.toString();
    if (lokasiText != null) request.fields['lokasi_text'] = lokasiText;
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    request.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final data = _decode(res);
    return Laporan.fromJson(data['data']);
  }

  // Update status laporan (khusus admin)
  Future<Laporan> updateStatus(int id, String status,
      {String? catatanAdmin}) async {
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';

    final res = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/laporans/$id/status'),
      headers: headers,
      body: jsonEncode({
        'status': status,
        if (catatanAdmin != null) 'catatan_admin': catatanAdmin,
      }),
    );

    final data = _decode(res);
    return Laporan.fromJson(data['data']);
  }

  Future<void> deleteLaporan(int id) async {
    final headers = await _authHeaders();
    final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/laporans/$id'),
        headers: headers);
    _decode(res);
  }

  // ================= HELPER =================

  dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    // Tangani error validasi Laravel (422) dengan pesan yang rapi
    if (res.statusCode == 422 && body['errors'] != null) {
      final errors = (body['errors'] as Map<String, dynamic>)
          .values
          .expand((e) => (e as List))
          .join('\n');
      throw ApiException(errors);
    }

    throw ApiException(
        body['message'] ?? 'Terjadi kesalahan (${res.statusCode})');
  }
}
