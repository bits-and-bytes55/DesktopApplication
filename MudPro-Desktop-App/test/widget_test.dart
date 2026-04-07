import 'package:flutter_test/flutter_test.dart';
import 'package:mudpro_desktop_app/main.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('MyApp renders an injected home widget', (
    WidgetTester tester,
  ) async {
    const marker = Key('test-home');

    await tester.pumpWidget(
      const MyApp(
        home: SizedBox(key: marker),
      ),
    );

    expect(find.byKey(marker), findsOneWidget);
  });
}
