import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/ui/theme/church_theme.dart';
import 'package:sigillum/ui/widgets/panic_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: buildChurchTheme(),
      home: Scaffold(appBar: AppBar(actions: [child])),
    );

void main() {
  group('PanicButton — comportamiento de purga', () {
    testWidgets('se renderiza como ícono de escudo', (tester) async {
      await tester.pumpWidget(_wrap(
        PanicButton(onConfirmed: () {}),
      ));
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('al pulsar muestra diálogo de confirmación', (tester) async {
      await tester.pumpWidget(_wrap(
        PanicButton(onConfirmed: () {}),
      ));
      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();

      expect(find.text('Borrar sesión'), findsOneWidget);
      expect(find.text('Borrar todo'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('confirmar llama al callback onConfirmed', (tester) async {
      var llamado = false;
      await tester.pumpWidget(_wrap(
        PanicButton(onConfirmed: () => llamado = true),
      ));

      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Borrar todo'));
      await tester.pumpAndSettle();

      expect(llamado, isTrue,
          reason: 'El callback de purga debe ejecutarse al confirmar');
    });

    testWidgets('cancelar NO llama al callback onConfirmed', (tester) async {
      var llamado = false;
      await tester.pumpWidget(_wrap(
        PanicButton(onConfirmed: () => llamado = true),
      ));

      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(llamado, isFalse,
          reason: 'Cancelar no debe ejecutar la purga');
    });

    testWidgets('el diálogo se cierra al cancelar', (tester) async {
      await tester.pumpWidget(_wrap(
        PanicButton(onConfirmed: () {}),
      ));

      await tester.tap(find.byType(PanicButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Borrar sesión'), findsNothing);
    });
  });
}
