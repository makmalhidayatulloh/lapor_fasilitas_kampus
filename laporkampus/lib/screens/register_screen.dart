import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _confirmCtrl.text,
          );

      if (!mounted) return;

      // Cukup pop kembali ke LoginScreen (yang sudah ditampilkan oleh
      // RootRouter di main.dart). JANGAN push route baru di sini,
      // karena RootRouter yang mengatur perpindahan Login <-> Home
      // berdasarkan status AuthProvider.
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil. Silakan login.'),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password (min. 6 karakter)',
                    border: OutlineInputBorder()),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Password minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Konfirmasi Password',
                    border: OutlineInputBorder()),
                validator: (v) => (v != _passwordCtrl.text)
                    ? 'Konfirmasi password tidak cocok'
                    : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
