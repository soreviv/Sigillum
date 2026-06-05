/// Estado efímero de la conversación. Vive exclusivamente en RAM.
/// No hay serialización, no hay escritura a disco, no hay persistencia.
library;

import 'dart:collection';

/// Un mensaje individual en la conversación.
final class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  final String role;    // 'user' | 'assistant'
  final String content;

  Map<String, String> toApiMap() => {'role': role, 'content': content};
}

/// Almacén de mensajes en RAM. Se destruye con el proceso o al llamar [purge].
final class ConversationMemory {
  final List<ChatMessage> _messages = [];

  /// Máximo de turnos conservados para no saturar el contexto de la API.
  static const int _maxTurns = 20;

  // ⚡ Bolt: Replace List.unmodifiable (which performs an O(N) allocation and copy)
  // with UnmodifiableListView (which is an O(1) wrapper). This prevents significant
  // Garbage Collection (GC) pressure and UI jank because `messages` is called frequently
  // (multiple times per second) during SSE streaming rebuilds.
  List<ChatMessage> get messages => UnmodifiableListView(_messages);

  bool get isEmpty => _messages.isEmpty;

  void addUser(String content) {
    _messages.add(ChatMessage(role: 'user', content: content));
    _trim();
  }

  void addAssistant(String content) {
    _messages.add(ChatMessage(role: 'assistant', content: content));
    _trim();
  }

  /// Reemplaza el último mensaje del asistente (para actualizar un stream en curso).
  void updateLastAssistant(String content) {
    if (_messages.isNotEmpty && _messages.last.role == 'assistant') {
      _messages[_messages.length - 1] = ChatMessage(role: 'assistant', content: content);
    } else {
      addAssistant(content);
    }
  }

  /// Destrucción irreversible. Llamar desde el Botón de Pánico y al cerrar la app.
  void purge() {
    _messages.clear();
  }

  /// Convierte al formato que espera la Claude API.
  List<Map<String, String>> toApiMessages() =>
      _messages.map((m) => m.toApiMap()).toList();

  void _trim() {
    // ⚡ Bolt: Use `removeRange` instead of a `while` loop calling `removeAt(0)`.
    // `removeAt(0)` in a loop takes O(N*k) time because it shifts all remaining
    // elements after every deletion. `removeRange` handles this in O(N).
    if (_messages.length > _maxTurns * 2) {
      _messages.removeRange(0, _messages.length - _maxTurns * 2);
    }
  }
}
