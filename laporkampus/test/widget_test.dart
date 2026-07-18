// Basic smoke test untuk memastikan aplikasi LaporFasilKam bisa di-build
// tanpa crash saat pertama kali dijalankan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:laporkampus/main.dart';

void main() {
  testWidgets('LaporFasilKam app builds without crashing',
      (WidgetTester tester) async {
    // Build aplikasi dan trigger satu frame.
    await tester.pumpWidget(const LaporFasilkamApp());

    // Karena belum login, seharusnya muncul indikator loading atau halaman Login.
    // Cukup pastikan tidak ada error saat widget tree pertama kali dirender.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
