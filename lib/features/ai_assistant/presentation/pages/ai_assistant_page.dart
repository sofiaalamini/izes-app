import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final AiAssistantService _assistantService = AiAssistantService();
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = const [
    ChatMessage(
      text:
          'Sou o Assistente IZES. Posso resumir prioridade, irrigacao, risco de praga e proximos passos.',
      isUser: false,
    ),
  ].toList();

  bool _loading = false;

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add(ChatMessage(text: question.trim(), isUser: true));
      _controller.clear();
    });

    try {
      final reply = await _assistantService.answerQuestion(question);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: '$error', isUser: false));
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Devo irrigar hoje?',
      'Qual talhao precisa de atencao?',
      'O que faco primeiro esta semana?',
      'Existe risco de praga?',
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(
                eyebrow: 'Assistente IZES',
                title:
                    'Pergunte em linguagem simples e receba resposta pratica.',
                description: 'Integrado ao endpoint /api/ia/chat do backend.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions
                    .map(
                      (item) => ActionChip(
                        label: Text(item),
                        onPressed: () => _sendQuestion(item),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ..._messages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: AppSurfaceCard(
                        backgroundColor: message.isUser
                            ? IzesColors.greenSoft
                            : IzesColors.surface,
                        child: Text(
                          message.text,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: IzesColors.ink),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ex.: Devo irrigar hoje?',
                    ),
                    onSubmitted: _sendQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () => _sendQuestion(_controller.text),
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
