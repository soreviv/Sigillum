import 'package:flutter/material.dart';
import '../../core/ai/claude_provider.dart';
import '../../core/ai/conversation_memory.dart';
import '../../core/ai/distillation_parser.dart';
import '../../core/ai/rag/rag_retriever.dart';
import '../../core/ai/system_prompt.dart';
import '../../core/privacy/keyboard_config.dart';
import '../../core/privacy/panic_handler.dart';
import '../theme/church_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/panic_button.dart';
import 'distillation_screen.dart';

/// Pantalla de Desahogo — el feligrés narra su situación libremente.
/// Toda la conversación vive en RAM; se destruye al pulsar el Botón de Pánico.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _memory = ConversationMemory();
  final _claude = ClaudeProvider();
  final _rag    = RagRetriever();

  final _controller     = TextEditingController();
  final _scrollCtrl     = ScrollController();
  final _focusNode      = FocusNode();

  bool   _isStreaming    = false;
  bool   _isGettingList  = false;
  final ValueNotifier<String> _streamBufferNotifier = ValueNotifier('');
  String? _error;

  bool get _hasAiResponse =>
      _memory.messages.any((m) => m.role == 'assistant');

  @override
  void dispose() {
    _memory.purge();
    _streamBufferNotifier.dispose();
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _streamNotifier.dispose();
    super.dispose();
  }

  // ── Acciones ────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isStreaming || _isGettingList) return;

    _controller.clear();
    await clearSystemClipboard();
    _error = null;
    _memory.addUser(text);
    _streamBufferNotifier.value = '';
    setState(() => _isStreaming = true);
    _scrollToBottom();

    final ragContext = await _rag.retrieve(text);
    final prompt = buildSystemPrompt(ragContext);

    // ⚡ Bolt: Throttled UI updates during stream parsing.
    // Rebuilding the widget tree and triggering scroll animations on every single
    // SSE chunk is an O(N²) operation that causes severe UI jank, especially when
    // parsing Markdown. By throttling updates to 50ms, we maintain smooth ~20fps
    // animations while drastically reducing CPU overhead.
    final stopwatch = Stopwatch()..start();

    final buffer = StringBuffer();
    // ⚡ Bolt: Throttling state updates during streaming prevents excessive
    // Widget re-renders (especially MarkdownBody) and scroll-animation queueing.
    final throttle = Stopwatch()..start();
    try {
      await for (final chunk in _claude.streamResponse(
        systemPrompt: prompt,
        memory: _memory,
      )) {
        buffer.write(chunk);
        _streamBuffer = buffer.toString();

        if (stopwatch.elapsedMilliseconds > 50) {
          setState(() {});
          _scrollToBottom();
          stopwatch.reset();
        }
      }
      // Ensure the final state is rendered.
      _streamBuffer = buffer.toString();
      setState(() {});
      _scrollToBottom();
      _memory.addAssistant(buffer.toString());
    } on ClaudeProviderException catch (e) {
      _memory.addAssistant('');
      setState(() => _error = e.userMessage);
    } finally {
      _streamBufferNotifier.value = '';
      setState(() => _isStreaming = false);
      _scrollToBottom();
    }
  }

  Future<void> _requestDistillation() async {
    _error = null;
    _memory.addUser('Dame mi lista de destilación estructurada.');
    _streamBufferNotifier.value = '';
    setState(() {
      _isGettingList = true;
      _isStreaming = true;
    });
    _scrollToBottom();

    final ragContext = await _rag.retrieve('especie número pecados confesar Canon 988');
    final prompt = buildSystemPrompt(ragContext);

    final stopwatch = Stopwatch()..start();

    final buffer = StringBuffer();
    // ⚡ Bolt: Throttling state updates during streaming.
    final throttle = Stopwatch()..start();
    try {
      await for (final chunk in _claude.streamResponse(
        systemPrompt: prompt,
        memory: _memory,
      )) {
        buffer.write(chunk);
        _streamBuffer = buffer.toString();

        if (stopwatch.elapsedMilliseconds > 50) {
          setState(() {});
          _scrollToBottom();
          stopwatch.reset();
        }
      }
      final response = buffer.toString();
      // Ensure the final state is rendered.
      _streamBuffer = response;
      setState(() {});
      _scrollToBottom();
      _memory.addAssistant(response);

      final sins = parseDistillation(response);
      if (sins.isEmpty) {
        setState(() {
          _error = 'No se pudo estructurar la lista. Continúa narrando tu situación.';
        });
        return;
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DistillationScreen(
            sins: sins,
            onPurgeAll: _purgeAll,
          ),
        ),
      );
    } on ClaudeProviderException catch (e) {
      _memory.addAssistant('');
      setState(() => _error = e.userMessage);
    } finally {
      _streamBufferNotifier.value = '';
      setState(() {
        _isGettingList = false;
        _isStreaming = false;
      });
    }
  }

  void _purgeAll() {
    _memory.purge();
    clearSystemClipboard();
    _controller.clear();
    _streamBufferNotifier.value = '';
    setState(() {
      _isStreaming   = false;
      _isGettingList = false;
      _error         = null;
    });
  }

  void _triggerPanic() async {
    _purgeAll();
    if (!mounted) return;
    await PanicHandler.purgeAndExit([_controller], context: context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sigillum', style: TextStyle(letterSpacing: 2)),
        actions: [
          PanicButton(onConfirmed: _triggerPanic),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (!_claude.isConfigured) const _ApiKeyWarning(),
          Expanded(child: _buildMessageList()),
          if (_error != null) _buildErrorBanner(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final msgs = _memory.messages;
    if (msgs.isEmpty && !_isStreaming) return const _EmptyState();

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: msgs.length + (_isStreaming ? 1 : 0),
      itemBuilder: (_, i) {
        if (i < msgs.length) {
          final m = msgs[i];
          if (m.content.isEmpty) return const SizedBox.shrink();
          return ChatBubble(message: m.content, isUser: m.role == 'user');
        }
        return ValueListenableBuilder<String>(
          valueListenable: _streamBufferNotifier,
          builder: (context, currentBuffer, child) {
            return ChatBubble(
              message: currentBuffer,
              isUser: false,
              isStreaming: true,
            );
          },
        );
      },
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      color: kPanic.withValues(alpha: 30 / 255),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(_error!, style: const TextStyle(color: kPanic, fontSize: 13)),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasAiResponse && !_isStreaming) _buildGetListButton(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SigillumKeyboardConfig.buildTextField(
                    controller: _controller,
                    hintText: 'Narra tu situación...',
                    maxLines: 4,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(
                  loading: _isStreaming,
                  onTap: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetListButton() {
    return InkWell(
      onTap: _isGettingList ? null : _requestDistillation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isGettingList)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: kGold),
              )
            else
              const Icon(Icons.format_list_bulleted, color: kGold, size: 18),
            const SizedBox(width: 8),
            Text(
              _isGettingList ? 'Estructurando lista...' : 'Obtener mi lista',
              style: const TextStyle(
                color: kGold,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets privados ──────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: loading ? kBorder : kGold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: kTextMuted,
                ),
              )
            : const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.edit_note, color: kTextMuted, size: 40),
            SizedBox(height: 16),
            Text(
              'Narra tu situación con libertad.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando termines, pulsa "Obtener mi lista" para recibir '
              'tu examen estructurado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextMuted, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiKeyWarning extends StatelessWidget {
  const _ApiKeyWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kPanic.withValues(alpha: 30 / 255),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'API key no configurada. Compila con --dart-define=ANTHROPIC_API_KEY=...',
        style: TextStyle(color: kPanic, fontSize: 12),
      ),
    );
  }
}
