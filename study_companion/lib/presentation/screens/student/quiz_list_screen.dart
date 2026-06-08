import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final studentQuizzesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/quizzes');
  return response.data;
});

class QuizListScreen extends ConsumerWidget {
  const QuizListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(studentQuizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Quizzes')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentQuizzesProvider),
        child: quizzesAsync.when(
          data: (quizzes) {
            if (quizzes.isEmpty) {
              return const Center(child: Text('No quizzes scheduled at the moment.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                final id = quiz['_id'];
                final title = quiz['title'] ?? 'Study Quiz';
                final subject = quiz['subject'] ?? '';
                final topic = quiz['topic'] ?? '';
                final difficulty = quiz['difficulty'] ?? 'Medium';
                final timeLimit = quiz['timeLimit'] ?? 10;
                final qCount = (quiz['questions'] as List?)?.length ?? 0;
                final isAi = quiz['isAiGenerated'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subject.toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            if (isAi)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                                    SizedBox(width: 4),
                                    Text('AI Generated', style: TextStyle(fontSize: 10, color: Colors.purple, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Topic: $topic', style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('$timeLimit mins', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.list_alt_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text('$qCount Questions', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.speed_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(difficulty, style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/quiz-attempt/$id'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('START QUIZ'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading quizzes: $e')),
        ),
      ),
    );
  }
}
