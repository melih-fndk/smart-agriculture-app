// Bu, projemiz için güncellenmiş ve anlamlı bir widget testidir.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tarimus/main.dart'; // Ana main.dart dosyamızı import ediyoruz

void main() {
  testWidgets('Uygulama baslatici testi (MaterialApp)', (
    WidgetTester tester,
  ) async {
    // Uygulamamızı (MyApp) build et ve bir kare çiz.
    await tester.pumpWidget(const MyApp());

    // Sayaç ('0' veya '1') aramak yerine,
    // uygulamamızın bir MaterialApp widget'ı içerip içermediğini kontrol ediyoruz.
    // Bu, uygulamanın çökmeden başarıyla başladığını doğrular.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
