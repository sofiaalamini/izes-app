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
        _messages.add(
          const ChatMessage(
            text: 'Nao consegui responder agora. Tente novamente em instantes.',
            isUser: false,
          ),
        );
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
                title: 'Pergunte direto',
                description: 'Respostas curtas para apoiar a decisao no campo.',
                compact: true,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),
              ..._messages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? IzesColors.greenSoft
                              : IzesColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: IzesColors.line),
                        ),
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
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppSurfaceCard(
                      backgroundColor: IzesColors.surfaceAlt,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Preparando resposta...'),
                        ],
                      ),
                    ),
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
                      hintText: 'Escreva sua pergunta',
                    ),
                    onSubmitted: _sendQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () => _sendQuestion(_controller.text),
                  child: const Icon(Icons.arrow_upward_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
