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
    ClaudeError.networkError =>
      'Sin conexión. Verifica tu red e intenta de nuevo.',
    ClaudeError.rateLimited => 'Demasiadas solicitudes. Espera un momento.',
    ClaudeError.serverError => 'Error temporal del servicio. Intenta de nuevo.',
  };
}

/// Cliente de la Claude API con soporte de streaming SSE.
/// La API key se inyecta en tiempo de compilación con --dart-define.
/// NUNCA se almacena ningún mensaje en disco.
class ClaudeProvider {
  ClaudeProvider({String? apiKey})
    : _apiKey =
          apiKey ??
          const String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _maxTokens = 2048;
  static const _apiVersion = '2023-06-01';

  final String _apiKey;

  // ⚡ Bolt: Usar un cliente HTTP persistente en lugar de request.send()
  // que abre y cierra sockets subyacentes por cada request, penalizando
  // severamente la latencia, especialmente durante el TLS handshake inicial.
  final http.Client _client = http.Client();

  bool get isConfigured => _apiKey.isNotEmpty;

  void dispose() {
    _client.close();
  }

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
      // ⚡ Bolt: Usando conexión HTTP keep-alive reutilizable
      response = await _client.send(request);
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
    // ⚡ Bolt: Replace manual, inefficient O(n²) string concatenation and splitting
    // with Dart's native `Utf8Decoder` and `LineSplitter`. This significantly reduces
    // memory allocations during streaming, preventing UI jank when receiving large
    // SSE payloads. It also correctly handles UTF-8 multi-byte characters split across chunks.
    final lines = byteStream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());

    await for (final line in lines) {
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
