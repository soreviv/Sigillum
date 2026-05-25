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

  // ⚡ Bolt: Compiled RegExps once to avoid re-compiling them on every single query
  static final _punctuationRegExp = RegExp(r'[^\wáéíóúüñ\s]');
  static final _whitespaceRegExp = RegExp(r'\s+');

  // ⚡ Bolt: Caches tokenization of static RAG content to avoid blocking the UI thread
  // Performance impact: Reduces CPU time significantly on subsequent retrieves since
  // strings are not re-tokenized or re-lowercased over and over again.
  final Map<String, Set<String>> _entryTokensCache = {};

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
      var entryTokens = _entryTokensCache[entry.id];
      if (entryTokens == null) {
        entryTokens = {
          ..._tokenize(entry.text),
          ...entry.keywords.map((k) => k.toLowerCase()),
        };
        _entryTokensCache[entry.id] = entryTokens;
      }

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
      .replaceAll(_punctuationRegExp, ' ')
      .split(_whitespaceRegExp)
      .where((t) => t.length > 2 && !_stopwords.contains(t))
      .toList();
}
