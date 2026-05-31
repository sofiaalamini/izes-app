import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  final List<ChatMessage> _messages = const [
    ChatMessage(
      text:
          'Sou o Assistente IZES. Posso resumir prioridade, irrigacao, risco de praga e proximos passos.',
      isUser: false,
    ),
  ].toList();

  bool _loading = false;
  String? _sensorId;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _loadingMessage = 'Analisando sensores e clima...';

  Future<void> _handleSend() async {
    if (_loading) return;

    final question = _controller.text.trim();
    if (_selectedImage != null && _selectedImageBytes != null) {
      await _sendImageWithOptionalMessage(
        image: _selectedImage!,
        imageBytes: _selectedImageBytes!,
        question: question,
      );
      return;
    }

    await _sendQuestion(question);
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _loadingMessage = 'Analisando sensores e clima...';
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

  Future<void> _pickImage(ImageSource source) async {
    if (_loading) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      final imageBytes = await image.readAsBytes();

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = imageBytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel abrir a camera ou galeria agora.'),
        ),
      );
    }
  }

  Future<void> _showImageSourceOptions() async {
    if (_loading) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImageWithOptionalMessage({
    required XFile image,
    required Uint8List imageBytes,
    required String question,
  }) async {
    if (_loading || (question.isEmpty && image.path.isEmpty)) return;

    setState(() {
      _loading = true;
      _loadingMessage = 'Analisando imagem...';
      _messages.add(
        ChatMessage(text: question, isUser: true, imageBytes: imageBytes),
      );
      _controller.clear();
      _selectedImage = null;
      _selectedImageBytes = null;
    });

    try {
      final sensorId = await _resolveSensorId();
      final reply = await _assistantService.analyzeImage(
        image.path,
        message: question,
        sensorId: sensorId,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
    } on AiAssistantException catch (error) {
      debugPrint('AiAssistantPage image send error: $error');
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: error.message, isUser: false));
        _loading = false;
      });
    } catch (_) {
      debugPrint('AiAssistantPage image send unexpected error.');
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text: 'Nao foi possivel analisar a imagem agora.',
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.imageBytes != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  message.imageBytes!,
                                  width: 132,
                                  height: 132,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (message.text.isNotEmpty)
                                const SizedBox(height: 12),
                            ],
                            if (message.text.isNotEmpty)
                              Text(
                                message.text,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: IzesColors.ink),
                              ),
                          ],
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
                          Text(_loadingMessage),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null &&
                      _selectedImageBytes != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedImage = null;
                                          _selectedImageBytes = null;
                                        });
                                      },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  Row(
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
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _loading ? null : _showImageSourceOptions,
                        tooltip: 'Enviar imagem',
                        icon: const Icon(Icons.photo_camera_outlined),
                        color: IzesColors.ink,
                      ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: _loading ? null : _handleSend,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(46, 46),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, size: 18),
                      ),
                    ],
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
