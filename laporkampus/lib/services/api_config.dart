class ApiConfig {
  // GANTI sesuai environment kamu:
  // - Android Emulator -> gunakan 10.0.2.2 (alias localhost dari sudut pandang emulator)
  // - HP fisik / iOS Simulator -> gunakan IP lokal komputer, misal 192.168.1.10
  // - Server production -> ganti dengan domain asli, misal https://api.lapor-fasilkam.my.id
  static const String baseUrl =
      'https://pushup-daringly-startup.ngrok-free.dev/api';

  // Base URL tanpa /api, dipakai untuk mengakses file storage (foto)
  static const String storageBaseUrl =
      'https://pushup-daringly-startup.ngrok-free.dev';
}
