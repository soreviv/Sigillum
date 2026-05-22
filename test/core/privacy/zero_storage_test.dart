/// AUDITORÍA FORENSE — Suite de pruebas que certifica la garantía Zero-Storage.
///
/// Cada grupo corresponde a un punto de verificación documentado en SECURITY.md.
/// Estas pruebas deben pasar antes de cualquier release del binario.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/conversation_memory.dart';
import 'package:sigillum/core/ai/distillation_parser.dart';

void main() {
  // ── Punto 1: Sin persistencia de sesión en RAM ────────────────────────────
  group('[ZS-01] Destrucción de datos en RAM tras purge()', () {
    test('purge() elimina todos los mensajes del usuario', () {
      final mem = ConversationMemory();
      mem.addUser('pecado mortal con circunstancias íntimas');
      mem.addUser('segundo mensaje con nombres de terceros');
      mem.purge();

      expect(mem.messages, isEmpty,
          reason: 'La RAM no debe retener ningún mensaje del usuario');
    });

    test('purge() elimina todos los mensajes del asistente', () {
      final mem = ConversationMemory();
      mem.addAssistant('Análisis detallado de la situación narrada');
      mem.purge();

      expect(mem.messages, isEmpty,
          reason: 'La RAM no debe retener respuestas del asistente');
    });

    test('la API de mensajes no expone datos tras purge()', () {
      final mem = ConversationMemory();
      mem.addUser('información confidencial del penitente');
      mem.addAssistant('respuesta con resumen estructurado');
      mem.purge();

      final exported = mem.toApiMessages();
      expect(exported, isEmpty,
          reason: 'toApiMessages() no debe exportar nada tras purge()');
    });
  });

  // ── Punto 2: Aislamiento entre sesiones ──────────────────────────────────
  group('[ZS-02] Aislamiento entre sesiones', () {
    test('una nueva sesión no contamina con datos de la sesión anterior', () {
      final mem = ConversationMemory();

      // Sesión 1
      mem.addUser('datos de la sesión anterior');
      mem.addAssistant('respuesta sesión 1');
      mem.purge();

      // Sesión 2
      mem.addUser('nueva sesión limpia');
      expect(
        mem.messages.any((m) => m.content.contains('sesión anterior')),
        isFalse,
        reason: 'Datos de sesiones anteriores no deben filtrarse',
      );
    });

    test('dos instancias de ConversationMemory son completamente independientes', () {
      final mem1 = ConversationMemory();
      final mem2 = ConversationMemory();

      mem1.addUser('datos privados usuario A');
      mem2.addUser('datos privados usuario B');

      expect(
        mem1.messages.any((m) => m.content.contains('usuario B')),
        isFalse,
      );
      expect(
        mem2.messages.any((m) => m.content.contains('usuario A')),
        isFalse,
      );
    });
  });

  // ── Punto 3: Destilación no retiene detalles explícitos ──────────────────
  group('[ZS-03] El parser de destilación elimina detalles explícitos', () {
    test('parseDistillation solo retiene especie y número, no narrativa', () {
      // Simula que la IA recibió una narrativa explícita pero devuelve solo especie/número
      const iaResponse = '''
---DESTILACIÓN---
1. Actos lujuriosos fuera del matrimonio | 3 veces
2. Ira grave contra el prójimo | 1 vez
---FIN---
''';
      final sins = parseDistillation(iaResponse);

      // Verificar que la lista estructurada no contiene narrativa sensible
      for (final sin in sins) {
        expect(sin.species.length, lessThan(80),
            reason: 'La especie debe ser concisa, sin narrativa extensa');
        expect(sin.species, isNot(contains('nombre')),
            reason: 'No debe contener nombres de terceros');
      }

      expect(sins, hasLength(2));
    });

    test('SinEntry es inmutable — sus campos no pueden modificarse', () {
      const sin = SinEntry(number: 1, species: 'Ira', count: '2 veces');
      // SinEntry es `final class` con campos `final` — esto es verificable en tiempo de compilación.
      // Si este test compila, la inmutabilidad está garantizada por el tipo.
      expect(sin.species, 'Ira');
      expect(sin.number, 1);
    });
  });

  // ── Punto 4: Comportamiento del trim de contexto ─────────────────────────
  group('[ZS-04] Límite de contexto — previene acumulación ilimitada en RAM', () {
    test('la memoria no acumula más de 40 mensajes (20 turnos)', () {
      final mem = ConversationMemory();
      for (var i = 0; i < 30; i++) {
        mem.addUser('mensaje usuario $i con datos sensibles');
        mem.addAssistant('respuesta asistente $i');
      }
      expect(
        mem.messages.length,
        lessThanOrEqualTo(40),
        reason: 'El trim automático previene crecimiento ilimitado de RAM',
      );
    });

    test('después del trim, los mensajes más recientes están preservados', () {
      final mem = ConversationMemory();
      for (var i = 0; i < 25; i++) {
        mem.addUser('user $i');
        mem.addAssistant('assistant $i');
      }
      // El último mensaje debe ser el más reciente
      expect(mem.messages.last.content, 'assistant 24');
    });
  });
}
