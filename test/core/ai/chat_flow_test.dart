/// Tests de integración — Flujo completo Chat → Destilación → QPL.
///
/// Usa respuestas simuladas para validar el pipeline completo sin API key.
/// Cubre la garantía Zero-Storage en cada transición de estado.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/conversation_memory.dart';
import 'package:sigillum/core/ai/distillation_parser.dart';
import 'package:sigillum/core/ai/system_prompt.dart';

void main() {
  // ── System Prompt ────────────────────────────────────────────────────────
  group('System Prompt — construcción con y sin RAG', () {
    test('incluye contexto RAG cuando se proporciona', () {
      const ragContext = 'Canon 988 §1: El fiel está obligado a confesar...';
      final prompt = buildSystemPrompt(ragContext);
      expect(prompt, contains('Canon 988'));
      expect(prompt, contains('DOCTRINA DE REFERENCIA'));
    });

    test('funciona sin contexto RAG (prompt base solamente)', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('REGLAS INQUEBRANTABLES'));
      expect(prompt, isNot(contains('DOCTRINA DE REFERENCIA')));
    });

    test('contiene todas las reglas de seguridad del prompt', () {
      final prompt = buildSystemPrompt('');
      expect(prompt, contains('NUNCA simules empatía'));
      expect(prompt, contains('NUNCA des la absolución'));
      expect(prompt, contains('ESPECIE'));
      expect(prompt, contains('NÚMERO'));
      expect(prompt, contains('---DESTILACIÓN---'));
      expect(prompt, contains('---QPL:'));
    });
  });

  // ── Flujo completo ─────────────────────────────────────────────────────
  group('Flujo completo: narrativa → destilación → QPL → purge', () {
    late ConversationMemory memory;

    setUp(() => memory = ConversationMemory());

    test('pipeline completo de 3 pantallas simulado', () {
      // Pantalla 1: Desahogo — usuario narra
      memory.addUser('He faltado a misa tres domingos seguidos y mentí a mi familia.');
      memory.addAssistant(
          'Gracias por tu honestidad. Has mencionado dos situaciones que pueden '
          'estructurarse para tu examen de conciencia.');

      expect(memory.messages.length, 2);

      // Pantalla 2: Destilación — IA produce lista estructurada
      memory.addUser('Dame mi lista de destilación estructurada.');

      const distillationResponse = '''
---DESTILACIÓN---
1. Omisión del precepto dominical | 3 veces
2. Mentira grave | 1 vez
---FIN---''';
      memory.addAssistant(distillationResponse);

      final sins = parseDistillation(distillationResponse);
      expect(sins, hasLength(2));
      expect(sins[0].species, 'Omisión del precepto dominical');
      expect(sins[0].count, '3 veces');
      expect(sins[1].species, 'Mentira grave');
      expect(sins[1].count, '1 vez');
      expect(sins[0].number, 1);
      expect(sins[1].number, 2);

      // Pantalla 3: QPL — preguntas para el sacerdote
      memory.addUser(
          'Genera las preguntas QPL para este pecado: "Omisión del precepto dominical".');

      const qplResponse = '''
---QPL:1---
P1: ¿Cómo puedo reorganizar mi semana para priorizar la misa dominical?
P2: ¿Qué práctica espiritual me recomienda para fortalecer mi compromiso?
---FIN---
''';
      memory.addAssistant(qplResponse);

      final qpl = parseQpl(qplResponse);
      expect(qpl, contains('P1:'));
      expect(qpl, contains('misa dominical'));
      expect(qpl, isNot(contains('---QPL:1---')));
      expect(qpl, isNot(contains('---FIN---')));

      // Verificar estado de la conversación
      expect(memory.messages.length, 6);

      // Purge y verificación Zero-Storage
      memory.purge();
      expect(memory.isEmpty, isTrue);
      expect(memory.toApiMessages(), isEmpty);
    });

    test('la destilación no retiene nombres ni detalles morbosos', () {
      memory.addUser('Cometí adulterio con la esposa de mi vecino Juan.');
      memory.addAssistant('''
---DESTILACIÓN---
1. Adulterio | 1 vez
---FIN---
''');

      final sins = parseDistillation(memory.messages.last.content);
      expect(sins[0].species, 'Adulterio');
      // La especie canónica NO debe contener nombres propios ni detalles
      expect(sins[0].species, isNot(contains('Juan')));
      expect(sins[0].species, isNot(contains('vecino')));
      expect(sins[0].species, isNot(contains('esposa')));

      memory.purge();
      expect(memory.isEmpty, isTrue);
    });

    test('QPL fallback funciona cuando la IA no usa el formato exacto', () {
      const rawQpl = 'P1: ¿Cómo puedo ser más caritativo con mi prójimo?';
      final parsed = parseQpl(rawQpl);
      // Sin bloque ---QPL:N---, debe devolver el texto limpio como fallback
      expect(parsed, rawQpl);
    });

    test('múltiples sesiones son independientes tras purge', () {
      // Sesión 1
      memory.addUser('Datos de sesión 1: mentí repetidamente.');
      memory.addAssistant('Respuesta sesión 1.');
      memory.purge();

      // Sesión 2
      memory.addUser('Nueva sesión limpia.');
      expect(memory.messages.length, 1);
      expect(
        memory.messages.any((m) => m.content.contains('sesión 1')),
        isFalse,
        reason: 'Datos de sesiones anteriores no deben filtrarse',
      );
    });
  });

  // ── Edge cases del parser ──────────────────────────────────────────────
  group('Parser — edge cases', () {
    test('destilación con pecados de especie larga', () {
      const text = '''
---DESTILACIÓN---
1. Actos de lujuria consentidos y deliberados contra la castidad conyugal | Varias veces al mes durante 6 meses
---FIN---''';
      final sins = parseDistillation(text);
      expect(sins, hasLength(1));
      expect(sins[0].count, contains('Varias veces'));
    });

    test('QPL con número de pecado de dos dígitos', () {
      const text = '---QPL:12---\nP1: ¿Pregunta de prueba?\n---FIN---';
      final qpl = parseQpl(text);
      expect(qpl, contains('P1:'));
    });

    test('destilación vacía no produce falsos positivos', () {
      const text = '---DESTILACIÓN---\n---FIN---';
      final sins = parseDistillation(text);
      expect(sins, isEmpty);
    });

    test('destilación con mezcla de líneas válidas e inválidas', () {
      const text = '''
---DESTILACIÓN---
Texto libre que no es un pecado
1. Pereza espiritual | 2 veces
Sin formato correcto
2. Ira | 5 veces
---FIN---''';
      final sins = parseDistillation(text);
      expect(sins, hasLength(2));
      expect(sins[0].species, 'Pereza espiritual');
      expect(sins[1].species, 'Ira');
    });
  });
}
