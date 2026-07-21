import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'session_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final SessionService _session = SessionService();

  UserModel? _user;
  bool _loading = true;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;

  AuthProvider() {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _user = await _session.getUser();
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _user = await _api.login(email, password);
    notifyListeners();
  }

  Future<void> register(
      String name, String email, String password, String confirm) async {
    // Panggil API register di sini
    await _api.register(name, email, password, confirm);
    // JANGAN simpan token atau set _isAuthenticated = true di sini!
    // Cukup return tanpa mengubah state login.
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }
}
