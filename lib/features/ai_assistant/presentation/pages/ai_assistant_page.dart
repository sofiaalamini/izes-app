import 'package:flutter/material.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/services/sensor_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_state_card.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final AiAssistantService _assistantService = AiAssistantService();
  final SensorService _sensorService = SensorService();
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = const [
    ChatMessage(
      text:
          'Sou o Assistente IZES. Posso resumir prioridade, irrigacao, risco de praga e proximos passos.',
      isUser: false,
    ),
  ].toList();

  bool _loading = false;
  String? _sensorId;

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _messages.add(ChatMessage(text: question.trim(), isUser: true));
      _controller.clear();
    });

    try {
      final sensorId = await _resolveSensorId();
      final reply = await _assistantService.answerQuestion(
        question,
        sensorId: sensorId,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
    } on AiAssistantException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: error.message, isUser: false));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text: 'Nao foi possivel consultar a IA agora.',
            isUser: false,
          ),
        );
        _loading = false;
      });
    }
  }

  Future<String?> _resolveSensorId() async {
    if (_sensorId != null && _sensorId!.isNotEmpty) {
      return _sensorId;
    }

    try {
      final sensors = await _sensorService.fetchSensors();
      if (sensors.isNotEmpty) {
        _sensorId = sensors.first.id;
      }
    } catch (_) {}

    return _sensorId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasConversation = _messages.any((message) => message.isUser);
    final visibleMessages = hasConversation ? _messages : _messages.skip(1);
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
                title: 'Apoio rapido para decidir no campo',
                description:
                    'Use o assistente para resumir prioridade, risco e proximos passos sem abrir varias telas.',
                compact: true,
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
              if (!hasConversation && !_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: AppStateCard(
                    title: 'Nenhuma conversa iniciada ainda',
                    message:
                        'Escolha uma pergunta acima ou escreva o que voce precisa decidir hoje.',
                    supportingText:
                        'Exemplos: irrigacao, risco de praga, sensores com atencao ou prioridade da semana.',
                  ),
                ),
              ...visibleMessages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: message.isUser
                              ? IzesColors.greenSoft
                              : IzesColors.surfaceSoft,
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
                      borderRadius: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Analisando sensores e clima...'),
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
            child: AppSurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Escreva sua pergunta',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onSubmitted: _sendQuestion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () => _sendQuestion(_controller.text),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(46, 46),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
