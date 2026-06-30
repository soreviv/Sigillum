import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'conversation_memory.dart';

enum AiProviderError { noApiKey, networkError, rateLimited, serverError }

class AiProviderException implements Exception {
  const AiProviderException(this.error);
  final AiProviderError error;

  String get userMessage => switch (error) {
    AiProviderError.noApiKey => 'La aplicación no está configurada correctamente.',
    AiProviderError.networkError =>
      'Sin conexión. Verifica tu red e intenta de nuevo.',
    AiProviderError.rateLimited => 'Demasiadas solicitudes. Espera un momento.',
    AiProviderError.serverError => 'Error temporal del servicio. Intenta de nuevo.',
  };
}

/// Cliente de la API de Mistral con soporte de streaming SSE.
/// La API key se inyecta en tiempo de compilación con --dart-define.
/// NUNCA se almacena ningún mensaje en disco.
class MistralProvider {
  MistralProvider({String? apiKey}) : _apiKey = _resolveKey(apiKey);

  static String _resolveKey(String? override) {
    if (override != null && override.isNotEmpty) return override;
    const fromEnv = String.fromEnvironment('MISTRAL_API_KEY', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.maybeGet('MISTRAL_API_KEY') ?? '';
  }

  static const _endpoint = 'https://api.mistral.ai/v1/chat/completions';
  static const _model = 'mistral-medium-latest';
  static const _maxTokens = 2048;

  static final http.Client _httpClient = http.Client();

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  void dispose() {
    _httpClient.close();
  }

  Stream<String> streamResponse({
    required String systemPrompt,
    required ConversationMemory memory,
  }) async* {
    if (!isConfigured) {
      throw const AiProviderException(AiProviderError.noApiKey);
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...memory.toApiMessages().map(
        (m) => {'role': m['role'] as String, 'content': m['content'] as String},
      ),
    ];

    final requestBody = {
      'model': _model,
      'messages': messages,
      'max_tokens': _maxTokens,
      'temperature': 0.7,
      'stream': true,
    };

    final request = http.Request('POST', Uri.parse(_endpoint));
    request.headers.addAll({
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'text/event-stream',
    });
    request.body = jsonEncode(requestBody);

    late http.StreamedResponse response;
    try {
      response = await _httpClient.send(request);
    } on Exception {
      throw const AiProviderException(AiProviderError.networkError);
    }

    if (response.statusCode == 429) {
      throw const AiProviderException(AiProviderError.rateLimited);
    }
    if (response.statusCode >= 500) {
      throw const AiProviderException(AiProviderError.serverError);
    }
    if (response.statusCode != 200) {
      throw const AiProviderException(AiProviderError.serverError);
    }

    yield* _parseSseStream(response.stream);
  }

  Stream<String> _parseSseStream(Stream<List<int>> byteStream) async* {
    final lines = byteStream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;

      final data = line.substring(6).trim();
      if (data == '[DONE]' || data.isEmpty) return;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;

        final delta = (choices.first as Map<String, dynamic>)['delta']
            as Map<String, dynamic>?;
        if (delta == null) continue;

        final text = delta['content'] as String?;
        if (text != null && text.isNotEmpty) yield text;
      } on FormatException {
        // Chunk malformado — ignorar
      }
    }
  }
}

// Aliases para compatibilidad con el código existente
typedef ClaudeProvider = MistralProvider;
typedef GeminiProvider = MistralProvider;
typedef ClaudeProviderException = AiProviderException;
typedef ClaudeError = AiProviderError;
