import 'canon_loader.dart';

/// Motor de recuperación RAG basado en puntuación TF-keyword.
/// Sin red, sin embeddings, sin dependencias externas.
/// Toda la búsqueda ocurre en RAM sobre los assets JSON estáticos.
class RagRetriever {
  RagRetriever({CanonLoader? loader})
      : _loader = loader ?? CanonLoader.instance;

  final CanonLoader _loader;

  // Stopwords en español que no aportan señal de recuperación
  static const _stopwords = {
    'de', 'la', 'el', 'en', 'y', 'a', 'que', 'los', 'las', 'un', 'una',
    'con', 'por', 'para', 'del', 'se', 'su', 'al', 'le', 'no', 'es',
    'lo', 'me', 'si', 'mi', 'te', 'yo', 'tu', 'he', 'ha', 'hay',
  };

  /// Retorna hasta [topK] entradas canónicas ordenadas por relevancia.
  /// El resultado se inyecta en el system prompt como contexto doctrinal.
  Future<String> retrieve(String query, {int topK = 3}) async {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return '';

    final all = await _loader.allEntries;

    // Calcular puntuación por entrada
    final scored = <(CanonEntry, int)>[];
    for (final entry in all) {
      var score = 0;
      final entryTokens = {
        ..._tokenize(entry.text),
        ...entry.keywords.map((k) => k.toLowerCase()),
      };

      for (final token in tokens) {
        if (entryTokens.contains(token)) score++;
        // Bonus por match en keywords (mayor señal que el texto libre)
        if (entry.keywords.any((k) => k.toLowerCase() == token)) score++;
      }

      if (score > 0) scored.add((entry, score));
    }

    // Ordenar descendente por puntuación, tomar los top K
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final top = scored.take(topK).map((s) => s.$1).toList();

    if (top.isEmpty) return '';
    return top
        .map((e) => '${e.reference}: ${e.text}')
        .join('\n\n');
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wáéíóúüñ\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 2 && !_stopwords.contains(t))
      .toList();
}
