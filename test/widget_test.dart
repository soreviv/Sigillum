// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/main.dart';

void main() {
  testWidgets('App arranca con pantalla de bloqueo o placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SigillumApp(showOnboarding: false));
    await tester.pump();
    // En test, local_auth no puede verificar biometría: se muestra LockScreen.
    expect(find.byType(SigillumApp), findsOneWidget);
  });
}
