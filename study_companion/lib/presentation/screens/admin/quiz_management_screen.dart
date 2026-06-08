import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';
import '../student/quiz_list_screen.dart';

class QuizManagementScreen extends ConsumerStatefulWidget {
  const QuizManagementScreen({super.key});

  @override
  ConsumerState<QuizManagementScreen> createState() => _QuizManagementScreenState();
}

class _QuizManagementScreenState extends ConsumerState<QuizManagementScreen> {
  final ApiClient _api = ApiClient();
  bool _isGenerating = false;

  // AI Form state
  final _aiSubjectController = TextEditingController();
  final _aiTopicController = TextEditingController();
  int _aiCount = 5;

  // Manual Form state
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  String _difficulty = 'Medium';
  int _timeLimit = 15;
  List<Map<String, dynamic>> _manualQuestions = [];

  @override
  void dispose() {
    _aiSubjectController.dispose();
    _aiTopicController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _generateQuizAI() async {
    final subject = _aiSubjectController.text.trim();
    final topic = _aiTopicController.text.trim();

    if (subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Subject and Topic", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final response = await _api.dio.post('/ai/generate-quiz', data: {
        'subject': subject,
        'topic': topic,
        'count': _aiCount,
      });

      final aiResult = response.data;
      setState(() => _isGenerating = false);

      // Open preview and edit dialog
      if (mounted) {
        _showAiPreviewDialog(aiResult);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      Fluttertoast.showToast(msg: "AI Generation failed: $e", backgroundColor: Colors.red);
    }
  }

  void _showAiPreviewDialog(dynamic quizData) {
    final titleController = TextEditingController(text: quizData['title'] ?? 'AI Quiz');
    final List questions = List.from(quizData['questions'] ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Preview AI Generated Quiz'),
          content: SizedBox(
            width: 450,
            height: 500,
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Quiz Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (c, idx) {
                      final q = questions[idx];
                      return Card(
                        child: ListTile(
                          title: Text('Q${idx + 1}: ${q['question']}'),
                          subtitle: Text('Ans: ${q['correctAnswer']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setDialogState(() {
                                questions.removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.dio.post('/quizzes', data: {
                    'title': titleController.text.trim(),
                    'subject': quizData['subject'] ?? 'General',
                    'topic': quizData['topic'] ?? 'General',
                    'difficulty': 'Medium',
                    'timeLimit': 15,
                    'questions': questions,
                    'isAiGenerated': true,
                  });
                  Fluttertoast.showToast(msg: "AI Quiz Published successfully!", backgroundColor: Colors.green);
                  ref.invalidate(studentQuizzesProvider);
                } catch (e) {
                  Fluttertoast.showToast(msg: "Failed to publish AI quiz: $e", backgroundColor: Colors.red);
                }
              },
              child: const Text('PUBLISH QUIZ'),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualQuestion() {
    final qController = TextEditingController();
    final ansController = TextEditingController();
    final expController = TextEditingController();
    String type = 'MCQ';
    List<String> options = [];
    final optController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['MCQ', 'TrueFalse', 'ShortAnswer'].map((t) {
                    return DropdownMenuItem(value: t, child: Text(t));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Question Type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (type == 'MCQ') ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: optController,
                          decoration: const InputDecoration(labelText: 'Add Option', border: OutlineInputBorder()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          if (optController.text.trim().isNotEmpty) {
                            setDialogState(() {
                              options.add(optController.text.trim());
                              optController.clear();
                            });
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    children: options.map((opt) {
                      return Chip(
                        label: Text(opt),
                        onDeleted: () => setDialogState(() => options.remove(opt)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: ansController,
                  decoration: const InputDecoration(labelText: 'Correct Answer', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expController,
                  decoration: const InputDecoration(labelText: 'Explanation', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () {
                if (qController.text.trim().isEmpty || ansController.text.trim().isEmpty) {
                  Fluttertoast.showToast(msg: "Question and Correct Answer are required", backgroundColor: Colors.orange);
                  return;
                }
                setState(() {
                  _manualQuestions.add({
                    'type': type,
                    'question': qController.text.trim(),
                    'options': type == 'MCQ' ? options : (type == 'TrueFalse' ? ['True', 'False'] : []),
                    'correctAnswer': ansController.text.trim(),
                    'explanation': expController.text.trim(),
                  });
                });
                Navigator.pop(ctx);
              },
              child: const Text('ADD QUESTION'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _publishManualQuiz() async {
    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();

    if (title.isEmpty || subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Title, Subject, and Topic", backgroundColor: Colors.orange);
      return;
    }

    if (_manualQuestions.isEmpty) {
      Fluttertoast.showToast(msg: "Please add at least one question", backgroundColor: Colors.orange);
      return;
    }

    try {
      await _api.dio.post('/quizzes', data: {
        'title': title,
        'subject': subject,
        'topic': topic,
        'difficulty': _difficulty,
        'timeLimit': _timeLimit,
        'questions': _manualQuestions,
        'isAiGenerated': false,
      });

      Fluttertoast.showToast(msg: "Manual Quiz Published Successfully!", backgroundColor: Colors.green);
      setState(() {
        _titleController.clear();
        _subjectController.clear();
        _topicController.clear();
        _manualQuestions = [];
      });
      ref.invalidate(studentQuizzesProvider);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to publish quiz: $e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzesAsync = ref.watch(studentQuizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Quizzes')),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          final mainForm = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAiGeneratorCard(),
              const SizedBox(height: 16),
              _buildManualCreatorCard(),
            ],
          );

          final quizList = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('All Published Quizzes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: quizzesAsync.when(
                  data: (quizzes) {
                    if (quizzes.isEmpty) {
                      return const Center(child: Text('No quizzes created yet.'));
                    }
                    return ListView.builder(
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        final q = quizzes[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(q['isAiGenerated'] == true ? Icons.auto_awesome_outlined : Icons.quiz_outlined),
                            title: Text(q['title'] ?? ''),
                            subtitle: Text('${q['subject']} • ${q['topic']}'),
                            trailing: Text('${(q['questions'] as List?)?.length ?? 0} Qs'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isPortrait
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        mainForm,
                        const SizedBox(height: 24),
                        SizedBox(height: 300, child: quizList),
                      ],
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 1, child: SingleChildScrollView(child: mainForm)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: quizList),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAiGeneratorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8),
                Text('AI Quiz Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _aiSubjectController,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aiTopicController,
              decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Question Count:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _aiCount,
                  items: [3, 5, 10, 15].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c.toString()));
                  }).toList(),
                  onChanged: (val) => setState(() => _aiCount = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateQuizAI,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GENERATE AI QUIZ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualCreatorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Create Quiz Manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Quiz Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    items: ['Easy', 'Medium', 'Hard'].map((d) {
                      return DropdownMenuItem(value: d, child: Text(d));
                    }).toList(),
                    onChanged: (val) => setState(() => _difficulty = val!),
                    decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _timeLimit.toString(),
                    decoration: const InputDecoration(labelText: 'Time Limit (mins)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() => _timeLimit = int.tryParse(val) ?? 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Questions Added: ${_manualQuestions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  onPressed: _addManualQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
            if (_manualQuestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(6)),
                child: ListView.builder(
                  itemCount: _manualQuestions.length,
                  itemBuilder: (c, idx) {
                    final q = _manualQuestions[idx];
                    return ListTile(
                      dense: true,
                      title: Text('Q${idx + 1}: ${q['question']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => setState(() => _manualQuestions.removeAt(idx)),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _publishManualQuiz,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('PUBLISH MANUAL QUIZ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
