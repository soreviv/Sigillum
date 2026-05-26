import 'canon_loader.dart';

/// Motor de recuperación RAG basado en puntuación TF-keyword + sinónimos.
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

  /// Mapa de sinónimos para pecados capitales y términos frecuentes de confesión.
  /// Mejora la recuperación cuando el usuario usa vocabulario coloquial
  /// en lugar de la terminología canónica exacta.
  static const _synonyms = <String, List<String>>{
    'soberbia': ['orgullo', 'vanidad', 'arrogancia', 'altivez', 'prepotencia'],
    'orgullo': ['soberbia', 'vanidad', 'arrogancia'],
    'avaricia': ['codicia', 'tacañería', 'ambición'],
    'codicia': ['avaricia', 'ambición'],
    'lujuria': ['impureza', 'lascivia', 'concupiscencia', 'fornicación'],
    'impureza': ['lujuria', 'lascivia'],
    'ira': ['cólera', 'rabia', 'enojo', 'furia', 'violencia'],
    'enojo': ['ira', 'cólera', 'rabia'],
    'gula': ['glotonería', 'exceso', 'intemperancia', 'ebriedad'],
    'envidia': ['celos', 'resentimiento', 'rivalidad'],
    'celos': ['envidia', 'resentimiento'],
    'pereza': ['acedia', 'dejadez', 'negligencia', 'tibieza'],
    'acedia': ['pereza', 'tibieza', 'negligencia'],
    'mentira': ['engaño', 'falsedad', 'calumnia', 'difamación'],
    'engaño': ['mentira', 'falsedad'],
    'robo': ['hurto', 'fraude', 'estafa'],
    'hurto': ['robo', 'fraude'],
    'adulterio': ['infidelidad', 'fornicación'],
    'infidelidad': ['adulterio'],
    'homicidio': ['asesinato', 'matar'],
    'aborto': ['homicidio'],
    'blasfemia': ['sacrilegio', 'irreverencia'],
    'idolatría': ['superstición'],
    'confesión': ['penitencia', 'reconciliación', 'sacramento'],
    'penitencia': ['confesión', 'reconciliación'],
    'pecado': ['falta', 'transgresión', 'ofensa'],
    'mortal': ['grave', 'gravísimo'],
    'venial': ['leve', 'menor'],
  };

  /// Retorna hasta [topK] entradas canónicas ordenadas por relevancia.
  /// El resultado se inyecta en el system prompt como contexto doctrinal.
  Future<String> retrieve(String query, {int topK = 3}) async {
    final tokens = _expandWithSynonyms(_tokenize(query));
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

  /// Expande los tokens del query con sinónimos para mejorar la recuperación.
  List<String> _expandWithSynonyms(List<String> tokens) {
    final expanded = <String>{...tokens};
    for (final token in tokens) {
      final syns = _synonyms[token];
      if (syns != null) expanded.addAll(syns);
    }
    return expanded.toList();
  }

  List<String> _tokenize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\wáéíóúüñ\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 2 && !_stopwords.contains(t))
      .toList();
}
