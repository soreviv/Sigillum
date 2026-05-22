import 'package:flutter_test/flutter_test.dart';
import 'package:sigillum/core/ai/rag/rag_retriever.dart';

/// Tests del motor RAG. Requieren el binding de Flutter para acceder a los assets
/// declarados en pubspec.yaml (assets/rag/cic.json y catecismo.json).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RagRetriever — recuperación sobre base canónica', () {
    late RagRetriever retriever;
    setUp(() => retriever = RagRetriever());

    testWidgets('retrieve devuelve texto no vacío para consulta sobre especie y número',
        (tester) async {
      final result = await retriever.retrieve('especie número pecados confesión Canon 988');
      expect(result, isNotEmpty,
          reason: 'Una consulta relevante debe recuperar al menos un canon');
      expect(result, contains('Canon 988'),
          reason: 'Canon 988 §1 es el más relevante para especie/número');
    });

    testWidgets('retrieve incluye Canon 983 para consulta sobre sigilo sacramental',
        (tester) async {
      final result = await retriever.retrieve('secreto sigilo sacramental confesión');
      expect(result, isNotEmpty);
      expect(result, contains('Canon 983'),
          reason: 'Canon 983 §1 cubre el sigilo sacramental');
    });

    testWidgets('retrieve devuelve string vacío para consulta sin relevancia canónica',
        (tester) async {
      final result = await retriever.retrieve('xyz abc 123 qrs');
      expect(result, isEmpty,
          reason: 'Consultas sin señal de recuperación deben devolver vacío');
    });

    testWidgets('retrieve no devuelve más de topK entradas', (tester) async {
      final result = await retriever.retrieve('pecado mortal venial especie', topK: 2);
      // Contamos las referencias por el patrón "Canon XXX:" o "CEC XXXX:"
      final matches = RegExp(r'(Canon \d+|CEC \d+)').allMatches(result).length;
      expect(matches, lessThanOrEqualTo(2),
          reason: 'topK=2 no debe devolver más de 2 entradas');
    });

    testWidgets('retrieve encuentra entradas del Catecismo para consulta de conciencia',
        (tester) async {
      final result = await retriever.retrieve('examen conciencia moral formación');
      expect(result, isNotEmpty);
      expect(result, contains('CEC'),
          reason: 'Las entradas del Catecismo deben ser recuperables');
    });
  });
}
