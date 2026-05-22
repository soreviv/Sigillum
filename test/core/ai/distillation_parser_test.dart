import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/distillation_parser.dart';

void main() {
  // ── parseDistillation ────────────────────────────────────────────────────
  group('parseDistillation', () {
    test('parsea bloque bien formado con dos entradas', () {
      const text = '''
---DESTILACIÓN---
1. Ira descontrolada | 3 veces aproximadamente
2. Omisión de oraciones | Varias semanas
---FIN---
''';
      final sins = parseDistillation(text);
      expect(sins, hasLength(2));
      expect(sins[0].number, 1);
      expect(sins[0].species, 'Ira descontrolada');
      expect(sins[0].count, '3 veces aproximadamente');
      expect(sins[1].species, 'Omisión de oraciones');
    });

    test('devuelve lista vacía si el bloque no existe', () {
      expect(parseDistillation('Respuesta sin formato'), isEmpty);
    });

    test('devuelve lista vacía si el texto está vacío', () {
      expect(parseDistillation(''), isEmpty);
    });

    test('acepta DESTILACION sin acento (fallback tipográfico de la IA)', () {
      const text = '---DESTILACION---\n1. Soberbia | 2 veces\n---FIN---';
      expect(parseDistillation(text), hasLength(1));
    });

    test('ignora líneas sin separador |', () {
      const text = '''
---DESTILACIÓN---
Línea sin pipe
2. Gula | 5 veces
---FIN---
''';
      final sins = parseDistillation(text);
      expect(sins, hasLength(1));
      expect(sins[0].species, 'Gula');
    });

    test('ignora líneas vacías dentro del bloque', () {
      const text = '---DESTILACIÓN---\n\n1. Envidia | 1 vez\n\n---FIN---';
      expect(parseDistillation(text), hasLength(1));
    });

    test('reasigna números secuencialmente (sin importar los de la IA)', () {
      const text = '''
---DESTILACIÓN---
3. Envidia | 2 veces
7. Lujuria | 4 veces
---FIN---
''';
      final sins = parseDistillation(text);
      expect(sins[0].number, 1);
      expect(sins[1].number, 2);
    });

    test('parsea lista de un único pecado', () {
      const text = '---DESTILACIÓN---\n1. Pereza espiritual | 1 vez\n---FIN---';
      final sins = parseDistillation(text);
      expect(sins, hasLength(1));
      expect(sins[0].species, 'Pereza espiritual');
    });

    test('recorta espacios en especie y cantidad', () {
      const text = '---DESTILACIÓN---\n1.   Avaricia   |   muchas veces   \n---FIN---';
      final sins = parseDistillation(text);
      expect(sins[0].species, 'Avaricia');
      expect(sins[0].count, 'muchas veces');
    });
  });

  // ── parseQpl ─────────────────────────────────────────────────────────────
  group('parseQpl', () {
    test('extrae el contenido del bloque QPL', () {
      const text = '''
---QPL:1---
P1: ¿Cómo cultivar la paciencia ante las injusticias?
P2: ¿Qué penitencia recomienda el confesor para la ira?
---FIN---
''';
      final qpl = parseQpl(text);
      expect(qpl, contains('P1:'));
      expect(qpl, contains('paciencia'));
      expect(qpl, isNot(contains('---QPL:1---')));
    });

    test('regresa el texto limpio si no hay bloque QPL', () {
      const raw = 'Texto sin formato QPL estructurado';
      expect(parseQpl(raw), 'Texto sin formato QPL estructurado');
    });

    test('funciona con número de pecado de dos dígitos', () {
      const text = '---QPL:12---\nP1: ¿Pregunta?\n---FIN---';
      expect(parseQpl(text), contains('P1:'));
    });

    test('devuelve string vacío si el bloque QPL está vacío', () {
      const text = '---QPL:1---\n\n---FIN---';
      expect(parseQpl(text), isEmpty);
    });
  });
}
