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

/// Lee una variable de entorno probando primero --dart-define y luego .env,
/// en el orden de nombres dado (el primero que resuelva algo, gana).
/// String.fromEnvironment exige un nombre constante en tiempo de compilación,
/// de ahí el switch explícito en vez de una búsqueda dinámica.
String _resolveEnv(List<String> names, {String defaultValue = ''}) {
  for (final name in names) {
    final fromDefine = switch (name) {
      'AI_PROVIDER' => const String.fromEnvironment('AI_PROVIDER'),
      'AI_API_KEY' => const String.fromEnvironment('AI_API_KEY'),
      'AI_ENDPOINT' => const String.fromEnvironment('AI_ENDPOINT'),
      'AI_MODEL' => const String.fromEnvironment('AI_MODEL'),
      'ANTHROPIC_API_KEY' => const String.fromEnvironment('ANTHROPIC_API_KEY'),
      'ANTHROPIC_MODEL' => const String.fromEnvironment('ANTHROPIC_MODEL'),
      'MISTRAL_API_KEY' => const String.fromEnvironment('MISTRAL_API_KEY'),
      'OPENAI_API_KEY' => const String.fromEnvironment('OPENAI_API_KEY'),
      _ => '',
    };
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromDotenv = dotenv.maybeGet(name) ?? '';
    if (fromDotenv.isNotEmpty) return fromDotenv;
  }
  return defaultValue;
}

/// Cliente de IA con soporte de streaming, agnóstico de proveedor.
/// La configuración se resuelve en tiempo de compilación (--dart-define) o desde .env.
/// NUNCA se almacena ningún mensaje en disco.
///
/// Selección de formato vía AI_PROVIDER=openai|anthropic:
/// - 'openai' (por defecto): API "chat completions" compatible con OpenAI.
///   Cubre Mistral, OpenAI, Groq, DeepSeek, LM Studio, Ollama, etc.
///   Config: AI_API_KEY, AI_ENDPOINT, AI_MODEL.
/// - 'anthropic': Anthropic Messages API nativa (formato de request/response
///   y streaming distinto del formato OpenAI).
///   Config: ANTHROPIC_API_KEY, ANTHROPIC_MODEL.
/// Si no se fija AI_PROVIDER explícitamente pero hay una ANTHROPIC_API_KEY
/// configurada, se usa 'anthropic' automáticamente.
abstract class AiProvider {
  factory AiProvider() {
    final format = _resolveEnv(['AI_PROVIDER']).toLowerCase();
    final hasAnthropicKey = _resolveEnv(['ANTHROPIC_API_KEY']).isNotEmpty;

    if (format == 'anthropic' || (format.isEmpty && hasAnthropicKey)) {
      return AnthropicProvider();
    }
    return OpenAiCompatibleProvider();
  }

  bool get isConfigured;

  void dispose();

  Stream<String> streamResponse({
    required String systemPrompt,
    required ConversationMemory memory,
  });
}

/// Proveedor "chat completions" compatible con OpenAI (Mistral, OpenAI, Groq,
/// DeepSeek, servidores locales OpenAI-compatible, etc.).
class OpenAiCompatibleProvider implements AiProvider {
  OpenAiCompatibleProvider({String? apiKey, String? endpoint, String? model})
      : _apiKey = apiKey ?? _resolveEnv(['AI_API_KEY', 'MISTRAL_API_KEY', 'OPENAI_API_KEY']),
        _endpoint = endpoint ??
            _resolveEnv(['AI_ENDPOINT'],
                defaultValue: 'https://api.mistral.ai/v1/chat/completions'),
        _model = model ?? _resolveEnv(['AI_MODEL'], defaultValue: 'mistral-medium-latest');

  static const _maxTokens = 2048;
  static final http.Client _httpClient = http.Client();

  final String _apiKey;
  final String _endpoint;
  final String _model;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  void dispose() {
    _httpClient.close();
  }

  @override
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

/// Proveedor que habla el formato nativo de la Anthropic Messages API
/// (request/response y streaming SSE distintos del formato OpenAI).
class AnthropicProvider implements AiProvider {
  AnthropicProvider({String? apiKey, String? model})
      : _apiKey = apiKey ?? _resolveEnv(['ANTHROPIC_API_KEY', 'AI_API_KEY']),
        _model = model ?? _resolveEnv(['ANTHROPIC_MODEL'], defaultValue: 'claude-sonnet-5');

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';
  static const _maxTokens = 2048;
  static final http.Client _httpClient = http.Client();

  final String _apiKey;
  final String _model;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  void dispose() {
    _httpClient.close();
  }

  @override
  Stream<String> streamResponse({
    required String systemPrompt,
    required ConversationMemory memory,
  }) async* {
    if (!isConfigured) {
      throw const AiProviderException(AiProviderError.noApiKey);
    }

    final requestBody = {
      'model': _model,
      'system': systemPrompt,
      'messages': memory.toApiMessages(),
      'max_tokens': _maxTokens,
      'temperature': 0.7,
      'stream': true,
    };

    final request = http.Request('POST', Uri.parse(_endpoint));
    request.headers.addAll({
      'x-api-key': _apiKey,
      'anthropic-version': _apiVersion,
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
      if (data.isEmpty) continue;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        if (json['type'] == 'content_block_delta') {
          final delta = json['delta'] as Map<String, dynamic>?;
          final text = delta?['text'] as String?;
          if (text != null && text.isNotEmpty) yield text;
        } else if (json['type'] == 'message_stop') {
          return;
        }
      } on FormatException {
        // Chunk malformado — ignorar
      }
    }
  }
}
