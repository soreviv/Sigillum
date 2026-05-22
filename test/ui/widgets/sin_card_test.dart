import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/distillation_parser.dart';
import 'package:sigillum/ui/theme/church_theme.dart';
import 'package:sigillum/ui/widgets/sin_card.dart';

const _testSin = SinEntry(
  number: 1,
  species: 'Ira descontrolada ante el prójimo',
  count: '3 veces aproximadamente',
);

Widget _wrap(Widget child) => MaterialApp(
      theme: buildChurchTheme(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('SinCard — renderizado y QPL', () {
    testWidgets('muestra especie y número del pecado', (tester) async {
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: null,
          isLoadingQpl: false,
          isExpanded: false,
          onToggleQpl: () {},
        ),
      ));

      expect(find.text('Ira descontrolada ante el prójimo'), findsOneWidget);
      expect(find.text('3 veces aproximadamente'), findsOneWidget);
    });

    testWidgets('muestra el botón QPL', (tester) async {
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: null,
          isLoadingQpl: false,
          isExpanded: false,
          onToggleQpl: () {},
        ),
      ));
      expect(find.text('¿Qué preguntarle al sacerdote?'), findsOneWidget);
    });

    testWidgets('pulsar botón QPL ejecuta el callback onToggleQpl', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: null,
          isLoadingQpl: false,
          isExpanded: false,
          onToggleQpl: () => toggled = true,
        ),
      ));

      await tester.tap(find.text('¿Qué preguntarle al sacerdote?'));
      await tester.pump();

      expect(toggled, isTrue);
    });

    testWidgets('muestra indicador de carga cuando isLoadingQpl es true', (tester) async {
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: null,
          isLoadingQpl: true,
          isExpanded: true,
          onToggleQpl: () {},
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra texto QPL cuando está expandido y cargado', (tester) async {
      const qpl = 'P1: ¿Cómo cultivar la paciencia?\nP2: ¿Qué penitencia sugiere?';
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: qpl,
          isLoadingQpl: false,
          isExpanded: true,
          onToggleQpl: () {},
        ),
      ));
      expect(find.text(qpl), findsOneWidget);
    });

    testWidgets('NO muestra texto QPL cuando está contraído', (tester) async {
      const qpl = 'P1: ¿Pregunta de prueba?';
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: qpl,
          isLoadingQpl: false,
          isExpanded: false,
          onToggleQpl: () {},
        ),
      ));
      expect(find.text(qpl), findsNothing);
    });

    testWidgets('muestra el número del pecado en el badge', (tester) async {
      await tester.pumpWidget(_wrap(
        SinCard(
          sin: _testSin,
          qplText: null,
          isLoadingQpl: false,
          isExpanded: false,
          onToggleQpl: () {},
        ),
      ));
      expect(find.text('1'), findsOneWidget);
    });
  });
}
