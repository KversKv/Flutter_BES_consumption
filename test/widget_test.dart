import 'package:bes_consumption/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shell renders navigation', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp(locale: Locale('en')));
    await tester.pump();

    expect(find.text('BLE CASE'), findsOneWidget);
    expect(find.text('BT CASE'), findsOneWidget);
    expect(find.text('Earbuds'), findsOneWidget);
    expect(find.text('WiFi CASE'), findsOneWidget);
  });
}
