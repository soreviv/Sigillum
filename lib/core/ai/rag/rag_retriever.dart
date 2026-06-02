import 'canon_loader.dart';

/// Motor de recuperación RAG basado en puntuación TF-keyword + sinónimos.
/// Sin red, sin embeddings, sin dependencias externas.
/// Toda la búsqueda ocurre en RAM sobre los assets JSON estáticos.
class RagRetriever {
  RagRetriever({CanonLoader? loader})
      : _loader = loader ?? CanonLoader.instance;

  final CanonLoader _loader;
  // ⚡ Bolt: Make cache static to avoid redundant tokenization across screen navigation.
  static final _cache = <String, _EntryCache>{};

  static final _punctuationRegExp = RegExp(r'[^\w\sáéíóúüñÁÉÍÓÚÜÑ]');
  static final _whitespaceRegExp = RegExp(r'\s+');

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
    'confesión': ['penitencia', 'reconciliación', 'sacramento', 'confesar'],
    'penitencia': ['confesión', 'reconciliación', 'confesar'],
    'confesar': ['confesión', 'penitencia'],
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
      // ⚡ Bolt: Cachear el texto tokenizado y los keywords en lowercase
      // para evitar recalcularlos en cada consulta a la base RAG.
      var cache = _cache[entry.id];
      if (cache == null) {
        final keywordsLower = entry.keywords.map((k) => k.toLowerCase()).toList();
        final textTokens = _tokenize(entry.text);
        cache = _EntryCache(
          allTokens: {...textTokens, ...keywordsLower},
          keywords: keywordsLower,
        );
        _cache[entry.id] = cache;
      }

      var score = 0;
      for (final token in tokens) {
        if (cache.allTokens.contains(token)) score++;
        // Bonus por match en keywords (mayor señal que el texto libre)
        if (cache.keywords.contains(token)) score++;
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
      .replaceAll(_punctuationRegExp, ' ')
      .split(_whitespaceRegExp)
      .where((t) => t.length > 2 && !_stopwords.contains(t))
      .toList();
}

class _EntryCache {
  const _EntryCache({required this.allTokens, required this.keywords});
  final Set<String> allTokens;
  final List<String> keywords;
}
