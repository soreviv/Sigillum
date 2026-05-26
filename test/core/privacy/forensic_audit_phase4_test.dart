/// AUDITORÍA FORENSE — Fase 4 — Suite ampliada de pruebas.
///
/// Certifica la garantía Zero-Storage en escenarios avanzados:
/// - Heap dump simulado: verificación de que strings sensibles no sobreviven a purge()
/// - Aislamiento entre componentes (Chat → Destilación → QPL)
/// - Comportamiento del trim bajo presión
/// - Inmutabilidad de estructuras de datos expuestas
/// - Verificación de que el RAG no retiene consultas del usuario
///
/// Referencia: SECURITY.md §"Auditoría Forense (Fase 4)"
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/conversation_memory.dart';
import 'package:sigillum/core/ai/distillation_parser.dart';
import 'package:sigillum/core/ai/rag/rag_retriever.dart';
import 'package:sigillum/core/ai/system_prompt.dart';

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 1: Heap Dump Simulado — strings sensibles no sobreviven a purge()
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-01] Heap Dump Simulado — purge() elimina datos sensibles', () {
    test('strings de narrativa sensible no persisten tras purge()', () {
      final mem = ConversationMemory();
      const sensitiveData = 'Cometí adulterio con María García el 15 de enero en su casa';

      mem.addUser(sensitiveData);
      mem.addAssistant('Análisis estructurado de la situación narrada.');
      mem.purge();

      // Verificar que ningún mensaje contiene datos sensibles
      expect(mem.messages, isEmpty);
      expect(mem.toApiMessages(), isEmpty);

      // Verificar que no hay rastro en la API de exportación
      final exported = mem.toApiMessages();
      for (final msg in exported) {
        expect(msg['content'], isNot(contains('María')));
        expect(msg['content'], isNot(contains('García')));
        expect(msg['content'], isNot(contains('adulterio')));
      }
    });

    test('datos de múltiples sesiones consecutivas no se filtran', () {
      final mem = ConversationMemory();

      // Sesión 1: datos extremadamente sensibles
      mem.addUser('Robé 5000 pesos a mi empleador el mes pasado');
      mem.addAssistant('Respuesta sesión 1');
      mem.purge();

      // Sesión 2: nuevos datos
      mem.addUser('He tenido pensamientos de envidia hacia mi hermano');
      mem.addAssistant('Respuesta sesión 2');

      // Verificar que sesión 1 no contamina sesión 2
      final allContent = mem.messages.map((m) => m.content).join(' ');
      expect(allContent, isNot(contains('Robé')));
      expect(allContent, isNot(contains('5000')));
      expect(allContent, isNot(contains('empleador')));

      mem.purge();
      expect(mem.isEmpty, isTrue);
    });

    test('purge() después de updateLastAssistant no deja residuos', () {
      final mem = ConversationMemory();

      mem.addUser('pregunta sensible');
      mem.addAssistant('respuesta parcial...');
      mem.updateLastAssistant('respuesta completa con datos estructurados');
      mem.purge();

      expect(mem.isEmpty, isTrue);
      expect(mem.toApiMessages(), isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 2: Aislamiento entre componentes
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-02] Aislamiento entre componentes', () {
    test('ConversationMemory de destilación es independiente del chat', () {
      // Simula el chat principal
      final chatMemory = ConversationMemory();
      chatMemory.addUser('Narrativa del chat principal');
      chatMemory.addAssistant('Respuesta del chat');

      // Simula la memoria de QPL (creada en DistillationScreen)
      final qplMemory = ConversationMemory();
      qplMemory.addUser('Genera QPL para pecado 1');

      // Verificar independencia total
      expect(chatMemory.messages.length, 2);
      expect(qplMemory.messages.length, 1);
      expect(
        qplMemory.messages.any((m) => m.content.contains('Narrativa')),
        isFalse,
      );

      // Purgar QPL no afecta chat
      qplMemory.purge();
      expect(qplMemory.isEmpty, isTrue);
      expect(chatMemory.messages.length, 2);
    });

    test('SinEntry es completamente inmutable', () {
      const sin = SinEntry(number: 1, species: 'Ira grave', count: '3 veces');

      // Verificar que los campos son final (esto es un test de compilación)
      expect(sin.number, 1);
      expect(sin.species, 'Ira grave');
      expect(sin.count, '3 veces');

      // SinEntry es `final class` — no se puede extender ni implementar
      // Este test pasa si compila, lo cual garantiza inmutabilidad por diseño.
    });

    test('parseDistillation no retiene estado entre llamadas', () {
      const response1 = '---DESTILACIÓN---\n1. Soberbia | 2 veces\n---FIN---';
      const response2 = '---DESTILACIÓN---\n1. Pereza | 1 vez\n---FIN---';

      final sins1 = parseDistillation(response1);
      final sins2 = parseDistillation(response2);

      // Cada llamada es independiente
      expect(sins1[0].species, 'Soberbia');
      expect(sins2[0].species, 'Pereza');
      expect(sins1, hasLength(1));
      expect(sins2, hasLength(1));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 3: Trim bajo presión — no acumula datos infinitamente
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-03] Trim bajo presión', () {
    test('100 mensajes rápidos no desbordan la memoria', () {
      final mem = ConversationMemory();
      for (var i = 0; i < 50; i++) {
        mem.addUser('Mensaje sensible número $i con detalles privados');
        mem.addAssistant('Respuesta $i con análisis estructurado');
      }

      // El trim debe mantener solo los últimos 40 mensajes (20 turnos)
      expect(mem.messages.length, lessThanOrEqualTo(40));

      // Los mensajes más antiguos (con datos sensibles tempranos) deben haber sido eliminados
      final firstContent = mem.messages.first.content;
      expect(firstContent, isNot(contains('número 0')));
      expect(firstContent, isNot(contains('número 1')));
    });

    test('purge() después de trim masivo deja la memoria completamente vacía', () {
      final mem = ConversationMemory();
      for (var i = 0; i < 100; i++) {
        mem.addUser('dato $i');
        mem.addAssistant('respuesta $i');
      }
      mem.purge();
      expect(mem.isEmpty, isTrue);
      expect(mem.messages, isEmpty);
      expect(mem.toApiMessages(), isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 4: RAG no retiene consultas del usuario
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-04] RAG — sin retención de consultas', () {
    testWidgets('RagRetriever no almacena queries entre llamadas', (tester) async {
      final rag = RagRetriever();

      // Primera consulta con datos sensibles
      final result1 = await rag.retrieve('adulterio esposa vecino Juan');

      // Segunda consulta diferente
      final result2 = await rag.retrieve('pereza oración misa');

      // Verificar que result2 no contiene datos de result1
      // (el RAG busca en los assets estáticos, no retiene queries)
      expect(result2, isNot(contains('adulterio')));

      // Verificar que los resultados son de fuentes canónicas
      if (result1.isNotEmpty) {
        expect(
          result1.contains('Canon') || result1.contains('CEC'),
          isTrue,
          reason: 'Los resultados del RAG deben ser de fuentes canónicas',
        );
      }
    });

    test('buildSystemPrompt no retiene contexto entre llamadas', () {
      // Construir prompt con contexto y verificar que no persiste
      buildSystemPrompt('Canon 983: Sigilo sacramental');
      final prompt2 = buildSystemPrompt('');

      // prompt2 no debe contener el contexto de prompt1
      expect(prompt2, isNot(contains('Canon 983')));
      expect(prompt2, isNot(contains('DOCTRINA DE REFERENCIA')));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 5: System Prompt — reglas de privacidad verificadas
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-05] System Prompt — reglas de privacidad', () {
    test('el prompt prohíbe explícitamente empatía simulada', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('NUNCA simules empatía'));
      expect(prompt, contains('entiendo'));
      expect(prompt, contains('lo siento'));
    });

    test('el prompt prohíbe dar absolución', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('NUNCA des la absolución'));
    });

    test('el prompt exige eliminar detalles morbosos', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('Elimina ABSOLUTAMENTE TODOS los detalles morbosos'));
    });

    test('el prompt define el formato exacto de destilación', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('---DESTILACIÓN---'));
      expect(prompt, contains('---FIN---'));
      expect(prompt, contains('[especie del pecado]'));
      expect(prompt, contains('[número aproximado]'));
    });

    test('el prompt define el formato QPL', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('---QPL:'));
      expect(prompt, contains('virtud opuesta'));
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // PUNTO 6: Verificación de toApiMessages — formato correcto para Claude
  // ══════════════════════════════════════════════════════════════════════════
  group('[FASE4-06] Formato de exportación API — sin datos extra', () {
    test('toApiMessages solo contiene role y content', () {
      final mem = ConversationMemory();
      mem.addUser('mensaje de prueba');
      mem.addAssistant('respuesta de prueba');

      final api = mem.toApiMessages();
      for (final msg in api) {
        expect(msg.keys, containsAll(['role', 'content']));
        expect(msg.keys.length, 2,
            reason: 'Solo role y content — sin metadata adicional');
      }
    });

    test('toApiMessages no expone timestamps ni IDs internos', () {
      final mem = ConversationMemory();
      mem.addUser('test');

      final api = mem.toApiMessages();
      final json = api.first.toString();
      expect(json, isNot(contains('timestamp')));
      expect(json, isNot(contains('id')));
      expect(json, isNot(contains('session')));
    });
  });
}
