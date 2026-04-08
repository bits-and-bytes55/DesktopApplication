import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mudpro_desktop_app/main.dart';

void main() {
  testWidgets('MyApp renders injected home widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        home: Scaffold(
          body: Center(
            child: Text('MudPro Smoke Test'),
          ),
        ),
      ),
    );

    expect(find.text('MudPro Smoke Test'), findsOneWidget);
  });
}
