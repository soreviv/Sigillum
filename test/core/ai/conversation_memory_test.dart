import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/conversation_memory.dart';

void main() {
  late ConversationMemory memory;

  setUp(() => memory = ConversationMemory());

  // ── Estado inicial ────────────────────────────────────────────────────────
  group('estado inicial', () {
    test('isEmpty es true al crear', () {
      expect(memory.isEmpty, isTrue);
    });

    test('messages está vacío al crear', () {
      expect(memory.messages, isEmpty);
    });

    test('toApiMessages devuelve lista vacía', () {
      expect(memory.toApiMessages(), isEmpty);
    });
  });

  // ── Adición de mensajes ───────────────────────────────────────────────────
  group('addUser / addAssistant', () {
    test('addUser registra rol user', () {
      memory.addUser('texto');
      expect(memory.messages.first.role, 'user');
      expect(memory.messages.first.content, 'texto');
    });

    test('addAssistant registra rol assistant', () {
      memory.addAssistant('respuesta');
      expect(memory.messages.first.role, 'assistant');
    });

    test('el orden de inserción se preserva', () {
      memory.addUser('u1');
      memory.addAssistant('a1');
      memory.addUser('u2');
      expect(memory.messages[0].role, 'user');
      expect(memory.messages[1].role, 'assistant');
      expect(memory.messages[2].role, 'user');
    });

    test('messages devuelve vista inmutable (no se puede modificar externamente)', () {
      memory.addUser('secreto');
      expect(
        () => (memory.messages as dynamic).add(
          const ChatMessage(role: 'user', content: 'inyección'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  // ── updateLastAssistant ───────────────────────────────────────────────────
  group('updateLastAssistant', () {
    test('reemplaza el último mensaje del asistente', () {
      memory.addUser('pregunta');
      memory.addAssistant('parcial');
      memory.updateLastAssistant('completo');
      expect(memory.messages.last.content, 'completo');
      expect(memory.messages.length, 2);
    });

    test('agrega nuevo mensaje si el último no es del asistente', () {
      memory.addUser('solo usuario');
      memory.updateLastAssistant('primera respuesta');
      expect(memory.messages.last.role, 'assistant');
      expect(memory.messages.length, 2);
    });
  });

  // ── toApiMessages ─────────────────────────────────────────────────────────
  group('toApiMessages', () {
    test('produce el formato correcto para la Claude API', () {
      memory.addUser('hola');
      memory.addAssistant('respuesta');
      final api = memory.toApiMessages();
      expect(api[0], {'role': 'user', 'content': 'hola'});
      expect(api[1], {'role': 'assistant', 'content': 'respuesta'});
    });
  });

  // ── Trim de contexto ──────────────────────────────────────────────────────
  group('trim de contexto (máx 20 turnos)', () {
    test('no supera 40 mensajes al agregar 25 turnos', () {
      for (var i = 0; i < 25; i++) {
        memory.addUser('user $i');
        memory.addAssistant('assistant $i');
      }
      expect(memory.messages.length, lessThanOrEqualTo(40));
    });
  });

  // ── AUDITORÍA FORENSE: purge() ────────────────────────────────────────────
  group('[FORENSE] purge() — garantía Zero-Storage', () {
    test('purge() vacía completamente la lista de mensajes', () {
      memory.addUser('pecado grave con datos sensibles');
      memory.addAssistant('respuesta del asistente');
      memory.purge();
      expect(memory.isEmpty, isTrue);
      expect(memory.messages, isEmpty);
    });

    test('después de purge, toApiMessages no expone datos previos', () {
      memory.addUser('dato muy sensible que no debe persistir');
      memory.purge();
      final api = memory.toApiMessages();
      expect(api, isEmpty);
      expect(api.any((m) => m['content']!.contains('sensible')), isFalse);
    });

    test('el objeto es reutilizable limpiamente después de purge', () {
      memory.addUser('primera sesión');
      memory.purge();
      memory.addUser('segunda sesión');
      expect(memory.messages.length, 1);
      expect(memory.messages.first.content, 'segunda sesión');
    });

    test('purge() sobre memoria vacía no lanza excepción', () {
      expect(() => memory.purge(), returnsNormally);
    });

    test('purge() múltiples veces consecutivas no lanza excepción', () {
      memory.addUser('mensaje');
      expect(() {
        memory.purge();
        memory.purge();
        memory.purge();
      }, returnsNormally);
      expect(memory.isEmpty, isTrue);
    });
  });
}
