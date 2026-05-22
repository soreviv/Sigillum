import 'package:flutter/material.dart';
import '../../core/ai/claude_provider.dart';
import '../../core/ai/conversation_memory.dart';
import '../../core/ai/distillation_parser.dart';
import '../../core/ai/rag/rag_retriever.dart';
import '../../core/ai/system_prompt.dart';
import '../../core/privacy/keyboard_config.dart';
import '../theme/church_theme.dart';
import '../widgets/panic_button.dart';
import '../widgets/sin_card.dart';

/// Pantalla de Destilación — muestra la lista canónica de pecados (especie/número)
/// y gestiona la carga on-demand de las preguntas QPL por falta.
class DistillationScreen extends StatefulWidget {
  const DistillationScreen({
    super.key,
    required this.sins,
    required this.onPurgeAll,
  });

  final List<SinEntry> sins;
  final VoidCallback onPurgeAll;

  @override
  State<DistillationScreen> createState() => _DistillationScreenState();
}

class _DistillationScreenState extends State<DistillationScreen> {
  final _claude = ClaudeProvider();
  final _rag    = RagRetriever();

  // Estado QPL por número de pecado
  final Map<int, String>  _qplTexts    = {};
  final Map<int, bool>    _qplExpanded = {};
  final Set<int>          _loadingQpls = {};

  @override
  void dispose() {
    // Limpiar portapapeles al salir de la destilación
    clearSystemClipboard();
    super.dispose();
  }

  // ── QPL ─────────────────────────────────────────────────────────────────

  Future<void> _toggleQpl(SinEntry sin) async {
    // Si ya está cargado, solo alternar expansión
    if (_qplTexts.containsKey(sin.number)) {
      setState(() {
        _qplExpanded[sin.number] = !(_qplExpanded[sin.number] ?? false);
      });
      return;
    }

    // Primer tap: cargar QPL
    setState(() {
      _loadingQpls.add(sin.number);
      _qplExpanded[sin.number] = true;
    });

    final memory = ConversationMemory();
    memory.addUser(
      'Genera las preguntas QPL para este pecado (sigue el formato ---QPL:${sin.number}--- exactamente): '
      '"${sin.species}" — ${sin.count}.',
    );

    final ragContext = await _rag.retrieve('${sin.species} virtud confesor pregunta');
    final prompt = buildSystemPrompt(ragContext);

    final buffer = StringBuffer();
    try {
      await for (final chunk in _claude.streamResponse(
        systemPrompt: prompt,
        memory: memory,
      )) {
        buffer.write(chunk);
      }
      if (mounted) {
        setState(() {
          _qplTexts[sin.number] = parseQpl(buffer.toString());
          _loadingQpls.remove(sin.number);
        });
      }
    } on ClaudeProviderException catch (e) {
      if (mounted) {
        setState(() {
          _qplTexts[sin.number] = e.userMessage;
          _loadingQpls.remove(sin.number);
        });
      }
    } finally {
      memory.purge();
    }
  }

  // ── Pánico desde esta pantalla ───────────────────────────────────────────

  void _handlePanic() {
    _qplTexts.clear();
    _qplExpanded.clear();
    _loadingQpls.clear();
    widget.onPurgeAll();
    clearSystemClipboard();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu lista', style: TextStyle(letterSpacing: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PanicButton(onConfirmed: _handlePanic),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: widget.sins.length,
              itemBuilder: (_, i) {
                final sin = widget.sins[i];
                return SinCard(
                  sin: sin,
                  qplText: _qplTexts[sin.number],
                  isLoadingQpl: _loadingQpls.contains(sin.number),
                  isExpanded: _qplExpanded[sin.number] ?? false,
                  onToggleQpl: () => _toggleQpl(sin),
                );
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.sins.length} falta${widget.sins.length != 1 ? "s" : ""} identificada${widget.sins.length != 1 ? "s" : ""}',
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pulsa "¿Qué preguntarle al sacerdote?" para obtener preguntas de diálogo.',
            style: TextStyle(color: kTextMuted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: const Text(
        'Esta lista será destruida al cerrar la app o pulsar el botón de borrado. '
        'Ningún dato se almacena.',
        textAlign: TextAlign.center,
        style: TextStyle(color: kTextMuted, fontSize: 11, height: 1.5),
      ),
    );
  }
}
