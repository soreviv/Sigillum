import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'conversation_memory.dart';

/// Errores del proveedor — sin exponer detalles sensibles al usuario.
enum ClaudeError { noApiKey, networkError, rateLimited, serverError }

class ClaudeProviderException implements Exception {
  const ClaudeProviderException(this.error);
  final ClaudeError error;

  String get userMessage => switch (error) {
        ClaudeError.noApiKey => 'La aplicación no está configurada correctamente.',
        ClaudeError.networkError => 'Sin conexión. Verifica tu red e intenta de nuevo.',
        ClaudeError.rateLimited => 'Demasiadas solicitudes. Espera un momento.',
        ClaudeError.serverError => 'Error temporal del servicio. Intenta de nuevo.',
      };
}

/// Cliente de la Claude API con soporte de streaming SSE.
/// La API key se inyecta en tiempo de compilación con --dart-define.
/// NUNCA se almacena ningún mensaje en disco.
class ClaudeProvider {
  ClaudeProvider({String? apiKey})
      : _apiKey = apiKey ??
            const String.fromEnvironment(
              'ANTHROPIC_API_KEY',
              defaultValue: '',
            );

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-5-20250929';
  static const _maxTokens = 2048;
  static const _apiVersion = '2023-06-01';

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Envía los mensajes a Claude y emite los fragmentos de texto conforme llegan.
  /// El estado de la conversación NO se persiste aquí; el llamador gestiona [ConversationMemory].
  Stream<String> streamResponse({
    required String systemPrompt,
    required ConversationMemory memory,
  }) async* {
    if (!isConfigured) {
      throw const ClaudeProviderException(ClaudeError.noApiKey);
    }

    final request = http.Request('POST', Uri.parse(_endpoint));
    request.headers.addAll({
      'x-api-key': _apiKey,
      'anthropic-version': _apiVersion,
      'content-type': 'application/json; charset=utf-8',
      // Sin caché de prompts para garantizar Zero Data Retention semántico.
      // Los datos no deben persistir entre llamadas en ningún layer.
    });

    request.body = jsonEncode({
      'model': _model,
      'max_tokens': _maxTokens,
      'stream': true,
      'system': systemPrompt,
      'messages': memory.toApiMessages(),
    });

    late http.StreamedResponse response;
    try {
      response = await request.send();
    } on Exception {
      throw const ClaudeProviderException(ClaudeError.networkError);
    }

    if (response.statusCode == 429) {
      throw const ClaudeProviderException(ClaudeError.rateLimited);
    }
    if (response.statusCode >= 500) {
      throw const ClaudeProviderException(ClaudeError.serverError);
    }
    if (response.statusCode != 200) {
      throw const ClaudeProviderException(ClaudeError.serverError);
    }

    yield* _parseSseStream(response.stream);
  }

  /// Parsea el stream SSE de Anthropic y emite solo los deltas de texto.
  /// Maneja correctamente chunks parciales que llegan en múltiples paquetes TCP.
  Stream<String> _parseSseStream(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    await for (final bytes in byteStream) {
      buffer.write(utf8.decode(bytes, allowMalformed: true));

      // Procesa líneas completas del buffer
      while (true) {
        final raw = buffer.toString();
        final newlineIdx = raw.indexOf('\n');
        if (newlineIdx == -1) break;

        final line = raw.substring(0, newlineIdx).trimRight();
        buffer.clear();
        buffer.write(raw.substring(newlineIdx + 1));

        if (!line.startsWith('data: ')) continue;

        final data = line.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['type'] == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>?;
            if (delta?['type'] == 'text_delta') {
              final text = delta!['text'] as String? ?? '';
              if (text.isNotEmpty) yield text;
            }
          }
        } on FormatException {
          // Chunk malformado — ignorar sin lanzar
        }
      }
    }
  }
}
