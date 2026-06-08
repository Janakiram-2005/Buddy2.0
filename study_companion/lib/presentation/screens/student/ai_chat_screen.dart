import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final ApiClient _api = ApiClient();
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'model',
      'text': 'Hello! I am your AI Study Companion. Ask me any questions about your topics, formulas, or concepts, or capture a photo of a problem, diagram, or textbook page for an explanation!',
      'timestamp': DateTime.now(),
    }
  ];

  File? _selectedImage;
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to access image source: $e", backgroundColor: Colors.red);
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final userMsg = {
      'role': 'user',
      'text': text.isEmpty ? "Analyzed attached image" : text,
      'imagePath': _selectedImage?.path,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _messages.add(userMsg);
      _textController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      // Format conversation history for Gemini (excluding timestamps/images)
      final historyPayload = _messages
          .where((m) => m['role'] != 'model' || _messages.indexOf(m) != 0) // exclude initial greeting for cleaner history
          .map((m) => {
                'role': m['role'],
                'text': m['text'],
              })
          .toList();

      // Clear the input image preview immediately upon sending
      setState(() {
        _selectedImage = null;
      });

      final response = await _api.dio.post('/ai/chat', data: {
        'message': text.isEmpty ? "Explain this image." : text,
        'imageBase64': imageBase64,
        'history': historyPayload,
      });

      final reply = response.data['reply'] ?? 'No response received from AI.';

      setState(() {
        _messages.add({
          'role': 'model',
          'text': reply,
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Sorry, I encountered an error responding to your request: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Assistant'),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Chat Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (msg['imagePath'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(msg['imagePath']),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey.shade900 : Colors.grey.shade100),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                              border: isUser 
                                  ? null 
                                  : Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                            ),
                            padding: const EdgeInsets.all(14.0),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white
                                    : (isDark ? Colors.white : Colors.black87),
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 8),
                    const Text('AI Companion is typing...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),

          // Selected Image Preview Panel
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Image attached. Press send to ask about it.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          // Bottom Input Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_photo_alternate_outlined, color: theme.colorScheme.primary),
                  onPressed: _showImageSourceOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type your study question...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
