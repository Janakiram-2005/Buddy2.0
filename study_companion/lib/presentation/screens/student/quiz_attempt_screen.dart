import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';

class QuizAttemptScreen extends StatefulWidget {
  final String quizId;
  const QuizAttemptScreen({super.key, required this.quizId});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen> {
  final ApiClient _api = ApiClient();
  dynamic _quiz;
  bool _isLoading = true;
  bool _isSubmitted = false;
  
  // Timer state
  Timer? _timer;
  int _secondsRemaining = 0;

  // Answers state
  Map<int, String> _selectedAnswers = {};
  final Map<int, TextEditingController> _shortAnswerControllers = {};

  // Submit results reference
  dynamic _submissionResult;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _shortAnswerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchQuiz() async {
    try {
      final response = await _api.dio.get('/quizzes/${widget.quizId}');
      setState(() {
        _quiz = response.data;
        _isLoading = false;
        _secondsRemaining = (_quiz['timeLimit'] ?? 10) * 60;
      });
      _startTimer();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching quiz: $e", backgroundColor: Colors.red);
      if (mounted) context.pop();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _handleSubmit(autoSubmit: true);
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSubmit({bool autoSubmit = false}) async {
    _timer?.cancel();
    if (autoSubmit) {
      Fluttertoast.showToast(msg: "Time is up! Submitting automatically.", backgroundColor: Colors.orange);
    }

    final questions = _quiz['questions'] as List;
    List<Map<String, dynamic>> answersList = [];
    int correctCount = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final type = q['type'];
      String selected = '';

      if (type == 'ShortAnswer') {
        selected = _shortAnswerControllers[i]?.text.trim() ?? '';
      } else {
        selected = _selectedAnswers[i] ?? '';
      }

      // Simple case-insensitive match for ShortAnswer, or exact for MCQ/TF
      final correct = q['correctAnswer'] ?? '';
      final isCorrect = selected.toLowerCase().trim() == correct.toLowerCase().trim();
      
      if (isCorrect) {
        correctCount++;
      }

      answersList.add({
        'questionIndex': i,
        'selectedAnswer': selected,
        'isCorrect': isCorrect,
      });
    }

    try {
      setState(() => _isLoading = true);
      final response = await _api.dio.post('/quizzes/${widget.quizId}/submit', data: {
        'score': correctCount,
        'totalQuestions': questions.length,
        'answers': answersList,
      });

      setState(() {
        _submissionResult = response.data;
        _isSubmitted = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "Error submitting quiz: $e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Preparing quiz questions...", style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }

    if (_isSubmitted) {
      return _buildResultsView();
    }

    final questions = _quiz['questions'] as List;
    final title = _quiz['title'] ?? 'Quiz';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_secondsRemaining),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(questions.length, (index) {
              final q = questions[index];
              return _buildQuestionCard(q, index);
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleSubmit(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('SUBMIT ANSWERS', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(dynamic q, int index) {
    final type = q['type'];
    final questionText = q['question'] ?? '';
    final options = q['options'] as List?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              questionText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (type == 'MCQ' && options != null)
              ...options.map((opt) {
                final isSelected = _selectedAnswers[index] == opt;
                return RadioListTile<String>(
                  title: Text(opt),
                  value: opt,
                  groupValue: _selectedAnswers[index],
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _selectedAnswers[index] = val!;
                    });
                  },
                );
              }),
            if (type == 'TrueFalse')
              Row(
                children: ['True', 'False'].map((val) {
                  final isSelected = _selectedAnswers[index] == val;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                          side: BorderSide(
                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedAnswers[index] = val;
                          });
                        },
                        child: Text(val),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (type == 'ShortAnswer')
              TextField(
                controller: _shortAnswerControllers.putIfAbsent(index, () => TextEditingController()),
                decoration: const InputDecoration(
                  labelText: 'Your Answer',
                  border: OutlineInputBorder(),
                  hintText: 'Type answer here...',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final questions = _quiz['questions'] as List;
    final correctCount = _submissionResult['score'] ?? 0;
    final totalCount = _submissionResult['totalQuestions'] ?? questions.length;
    final percentage = totalCount > 0 ? (correctCount / totalCount) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: percentage >= 70 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: percentage >= 70 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      percentage >= 70 ? Icons.check_circle_outline : Icons.error_outline,
                      size: 60,
                      color: percentage >= 70 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Score: $correctCount / $totalCount',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Percentage: ${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: percentage >= 70 ? Colors.green[800] : Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Answer Explanations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(questions.length, (index) {
              final q = questions[index];
              final qText = q['question'] ?? '';
              final explanation = q['explanation'] ?? 'No explanation provided.';
              final correctAns = q['correctAnswer'] ?? '';
              
              // Find what student chose
              final studentAns = q['type'] == 'ShortAnswer'
                  ? (_shortAnswerControllers[index]?.text ?? '')
                  : (_selectedAnswers[index] ?? 'Not answered');

              final isCorrect = studentAns.toLowerCase().trim() == correctAns.toLowerCase().trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Question ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(qText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Text('Your Answer: $studentAns', style: TextStyle(color: isCorrect ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.w500)),
                      Text('Correct Answer: $correctAns', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Explanation:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(explanation, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('BACK TO QUIZZES'),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
