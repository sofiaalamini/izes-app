import 'dart:typed_data';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/izes_models.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/izes_theme.dart';
import '../../../../shared/widgets/app_surface_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../widgets/ai_reply_view.dart';
import '../widgets/sensor_picker_sheet.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  static const _historyKey = 'chat_historico';
  static const _historyLimit = 20;
  static const _suggestions = [
    'Como está o solo aqui?',
    'Preciso irrigar agora?',
    'Tem algum problema nesse sensor?',
    'A temperatura está boa para a lavoura?',
    'O que devo fazer primeiro?',
  ];

  static final List<_ChatConversation> _history = [];
  static bool _historyLoaded = false;

  final AiAssistantService _assistantService = AiAssistantService();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  late final List<ChatMessage> _messages;
  String _conversationId = DateTime.now().microsecondsSinceEpoch.toString();

  bool _loading = false;
  String? _sensorId;
  String? _sensorLabel;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String _loadingMessage = 'Analisando sensores e clima...';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _messages = [
      const ChatMessage(
        text:
            'Sou o Assistente IZES. Posso resumir prioridade, irrigação, risco de praga e próximos passos.',
        isUser: false,
      ),
    ];
  }

  Future<void> _loadHistory() async {
    if (_historyLoaded) return;
    _historyLoaded = true;
    final saved = await CacheService().read(_historyKey);
    final items = saved?.data['conversas'];
    if (items is! List) return;
    _history
      ..clear()
      ..addAll(
        items.whereType<Map<String, dynamic>>().map(_ChatConversation.fromJson),
      );
  }

  Future<void> _persistHistory() async {
    await CacheService().save(_historyKey, {
      'conversas': _history.map((item) => item.toJson()).toList(),
    });
  }

  void _startNewConversation() {
    if (_loading) return;
    _saveCurrentConversation();
    setState(() {
      _conversationId = DateTime.now().microsecondsSinceEpoch.toString();
      _messages.removeRange(1, _messages.length);
      _controller.clear();
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

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

  /// Abre a lista de sensores. Ao escolher, a conversa passa a falar só desse sensor.
  Future<void> _pickSensor() async {
    if (_loading) return;
    final sensor = await showSensorPicker(context, selectedId: _sensorId);
    if (sensor == null || !mounted || sensor.id == _sensorId) return;

    final firstSensor = _sensorId == null;
    setState(() {
      _sensorId = sensor.id;
      _sensorLabel = sensor.label;
      _messages.add(
        ChatMessage(
          text: firstSensor
              ? 'Certo, vamos falar do ${sensor.label}. O que você quer saber?'
              : 'Agora estamos falando do ${sensor.label}.',
          isUser: false,
        ),
      );
    });
    _saveCurrentConversation();
  }

  Future<void> _sendQuestion(String question) async {
    if (question.trim().isEmpty || _loading) return;

    // Sem sensor escolhido a IA não analisa nada: primeiro pergunta de qual sensor é.
    if (_sensorId == null) {
      setState(() {
        _messages
          ..add(ChatMessage(text: question.trim(), isUser: true))
          ..add(
            const ChatMessage(
              text:
                  'Olá! Sobre qual sensor você quer falar? Toque em "Escolher sensor" aqui embaixo.',
              isUser: false,
            ),
          );
        _controller.clear();
      });
      await _pickSensor();
      return;
    }

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
      _saveCurrentConversation();
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
            text: 'Não foi possível consultar a IA agora.',
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
        maxWidth: 1600,
        maxHeight: 1600,
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
          content: Text('Não foi possível abrir a câmera ou galeria agora.'),
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
      debugPrint('Picked image path: ${image.path}');
      debugPrint('Picked image filename: ${image.name}');
      debugPrint('Picked image size bytes: ${imageBytes.length}');
      final sensorId = await _resolveSensorId();
      final reply = await _assistantService.analyzeImage(
        image.path,
        imageBytes: imageBytes,
        fileName: image.name,
        message: question,
        sensorId: sensorId,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _loading = false;
      });
      _saveCurrentConversation();
    } on AiAssistantException catch (error) {
      debugPrint('AiAssistantPage image send error: $error');
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: error.message, isUser: false));
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('AiAssistantPage image send unexpected error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text: 'Não foi possível analisar a imagem agora. Tente novamente.',
            isUser: false,
          ),
        );
        _loading = false;
      });
    }
  }

  /// A conversa é sempre sobre um sensor; fotos podem ir sem sensor.
  Future<String?> _resolveSensorId() async => _sensorId;

  @override
  void dispose() {
    _saveCurrentConversation();
    _controller.dispose();
    super.dispose();
  }

  /// Guarda a conversa atual no histórico. Uma conversa reaberta do histórico
  /// atualiza o mesmo item em vez de criar outro.
  void _saveCurrentConversation() {
    if (!_messages.any((message) => message.isUser)) return;

    final saved = _ChatConversation(
      id: _conversationId,
      createdAt: DateTime.now(),
      messages: List<ChatMessage>.of(_messages),
      sensorId: _sensorId,
      sensorLabel: _sensorLabel,
    );
    final index = _history.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _history[index] = saved;
    } else {
      _history.add(saved);
    }
    if (_history.length > _historyLimit) {
      _history.removeRange(0, _history.length - _historyLimit);
    }
    _persistHistory();
  }

  Future<void> _showHistory() async {
    _saveCurrentConversation();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final conversations = _history.reversed.toList();
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        'Conversas anteriores',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (conversations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
                        child: Text('Nenhuma conversa salva ainda.'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: conversations.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: IzesColors.greenSoft,
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: IzesColors.green,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                conversation.preview,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  if (conversation.sensorLabel != null)
                                    conversation.sensorLabel!,
                                  conversation.when,
                                ].join(' • '),
                              ),
                              trailing: IconButton(
                                tooltip: 'Apagar conversa',
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () {
                                  setSheetState(
                                    () => _history.removeWhere(
                                      (item) => item.id == conversation.id,
                                    ),
                                  );
                                  _persistHistory();
                                },
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                setState(() {
                                  _conversationId = conversation.id;
                                  _sensorId = conversation.sensorId;
                                  _sensorLabel = conversation.sensorLabel;
                                  _messages
                                    ..clear()
                                    ..addAll(conversation.messages);
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasConversation = _messages.any((message) => message.isUser);
    final visibleMessages = hasConversation ? _messages : _messages.skip(1);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: SectionHeader(
                      eyebrow: 'Assistente IZES',
                      title: 'Pergunte sobre sua lavoura',
                      description:
                          'Eu olho o que os sensores estão vendo e explico o problema em poucas palavras.',
                      compact: true,
                    ),
                  ),
                  if (hasConversation)
                    IconButton(
                      onPressed: _startNewConversation,
                      tooltip: 'Nova conversa',
                      icon: const Icon(Icons.add_comment_outlined),
                    ),
                  IconButton(
                    onPressed: _showHistory,
                    tooltip: 'Histórico de conversas',
                    icon: const Icon(Icons.history_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasConversation && !_loading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _sensorId == null
                      ? AppSurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Qual sensor vamos analisar?',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Escolha um sensor para eu olhar só o que ele está vendo.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _pickSensor,
                                icon: const Icon(Icons.sensors_rounded),
                                label: const Text('Escolher sensor'),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toque em uma pergunta para começar',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final suggestion in _suggestions)
                                  ActionChip(
                                    label: Text(suggestion),
                                    onPressed: () => _sendQuestion(suggestion),
                                    backgroundColor: IzesColors.surface,
                                    side: const BorderSide(
                                      color: IzesColors.line,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: IzesColors.greenDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
                            if (message.text.isNotEmpty && message.isUser)
                              Text(
                                message.text,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: IzesColors.ink),
                              )
                            else if (message.text.isNotEmpty)
                              AiReplyView(text: message.text),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppSurfaceCard(
                      backgroundColor: IzesColors.surfaceAlt,
                      borderRadius: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ActionChip(
                    avatar: Icon(
                      Icons.sensors_rounded,
                      size: 18,
                      color: _sensorId == null
                          ? IzesColors.cream
                          : IzesColors.green,
                    ),
                    label: Text(
                      _sensorId == null
                          ? 'Escolher sensor'
                          : '${_sensorLabel ?? 'Sensor'} • Trocar',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: _loading ? null : _pickSensor,
                    backgroundColor: _sensorId == null
                        ? IzesColors.green
                        : IzesColors.greenSoft,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _sensorId == null
                          ? IzesColors.cream
                          : IzesColors.greenDark,
                    ),
                  ),
                ),
                AppSurfaceCard(
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
                              textInputAction: TextInputAction.send,
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
                            onPressed: _loading
                                ? null
                                : _showImageSourceOptions,
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
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatConversation {
  const _ChatConversation({
    required this.id,
    required this.createdAt,
    required this.messages,
    this.sensorId,
    this.sensorLabel,
  });

  factory _ChatConversation.fromJson(Map<String, dynamic> json) {
    final messages = json['mensagens'];
    return _ChatConversation(
      id: '${json['id']}',
      createdAt:
          DateTime.tryParse('${json['data']}')?.toLocal() ?? DateTime.now(),
      sensorId: json['sensor_id'] as String?,
      sensorLabel: json['sensor_nome'] as String?,
      messages: messages is List
          ? messages
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => ChatMessage(
                    text: '${item['texto']}',
                    isUser: item['usuario'] == true,
                  ),
                )
                .toList()
          : const [],
    );
  }

  final String id;
  final DateTime createdAt;
  final List<ChatMessage> messages;
  final String? sensorId;
  final String? sensorLabel;

  /// Só texto: fotos não são guardadas no histórico.
  Map<String, dynamic> toJson() => {
    'id': id,
    'data': createdAt.toUtc().toIso8601String(),
    'sensor_id': sensorId,
    'sensor_nome': sensorLabel,
    'mensagens': [
      for (final message in messages)
        if (message.text.trim().isNotEmpty)
          {'texto': message.text, 'usuario': message.isUser},
    ],
  };

  String get preview {
    final userMessage = messages.firstWhere(
      (message) => message.isUser && message.text.trim().isNotEmpty,
      orElse: () => const ChatMessage(text: 'Análise de imagem', isUser: true),
    );
    return userMessage.text.trim();
  }

  String get when {
    final now = DateTime.now();
    final sameDay =
        now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    final hour = DateFormat('HH:mm').format(createdAt);
    return sameDay
        ? 'Hoje, $hour'
        : '${DateFormat('dd/MM').format(createdAt)}, $hour';
  }
}
