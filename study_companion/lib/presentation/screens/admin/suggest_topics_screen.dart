import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

class SuggestTopicsScreen extends ConsumerStatefulWidget {
  const SuggestTopicsScreen({super.key});

  @override
  ConsumerState<SuggestTopicsScreen> createState() => _SuggestTopicsScreenState();
}

class _SuggestTopicsScreenState extends ConsumerState<SuggestTopicsScreen> {
  final ApiClient _api = ApiClient();
  final _descController = TextEditingController();

  String _selectedSubject = 'Physics';
  List<dynamic> _suggestions = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final response = await _api.dio.post('/ai/suggest-topics', data: {
        'subject': _selectedSubject,
        'description': _descController.text.trim(),
      });

      setState(() {
        _suggestions = response.data as List;
      });

      if (_suggestions.isEmpty) {
        Fluttertoast.showToast(msg: "No topics returned. Try revising your description.", backgroundColor: Colors.orange);
      } else {
        Fluttertoast.showToast(msg: "Successfully generated topics!", backgroundColor: Colors.green);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "AI Generation failed: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(
      msg: "$label copied to clipboard!",
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Topic Suggestions'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 0,
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggest Study Topics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select a subject and add custom guidelines or curriculum focuses. Gemini will generate structured topic cards with detailed descriptions.',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Inputs Panel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Physics', 'Chemistry', 'Mathematics', 'Biology', 'General Study']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedSubject = val!),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Focus / Guidelines (Optional)',
                          hintText: 'e.g. Focus on rotational dynamics formulas, Newton\'s laws, or prepare for grade 11 level questions.',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _fetchSuggestions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('GENERATE TOPICS', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Results Title
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Querying Gemini AI for structured topics...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (_suggestions.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    'Suggested Topics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final sug = _suggestions[index];
                    final topicTitle = sug['topic'] ?? '';
                    final topicDesc = sug['description'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    topicTitle,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () => _copyToClipboard(topicTitle, "Topic title"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topicDesc,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.schedule, size: 16),
                                  label: const Text('Schedule'),
                                  onPressed: () {
                                    _copyToClipboard(topicTitle, "Topic");
                                    context.push('/admin/schedules');
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.quiz_outlined, size: 16),
                                  label: const Text('Quiz'),
                                  onPressed: () {
                                    _copyToClipboard(topicTitle, "Topic");
                                    context.push('/admin/quizzes');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No recommendations yet. Press generate to start.',
                      style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
