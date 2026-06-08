import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final adminSubmissionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/submissions/all');
  return response.data;
});

class SubmissionReviewScreen extends ConsumerStatefulWidget {
  const SubmissionReviewScreen({super.key});

  @override
  ConsumerState<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends ConsumerState<SubmissionReviewScreen> {
  final ApiClient _api = ApiClient();

  Future<void> _submitFeedback(String id, String feedbackText) async {
    if (feedbackText.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please type feedback first", backgroundColor: Colors.orange);
      return;
    }

    try {
      await _api.dio.patch('/submissions/$id/feedback', data: {
        'feedback': feedbackText.trim()
      });
      Fluttertoast.showToast(msg: "Feedback sent!", backgroundColor: Colors.green);
      ref.invalidate(adminSubmissionsProvider);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to send feedback: $e", backgroundColor: Colors.red);
    }
  }

  void _showFeedbackDialog(dynamic sub) {
    final controller = TextEditingController(text: sub['adminFeedback'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Review Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Topic: ${sub['topic']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Feedback Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitFeedback(sub['_id'], controller.text);
            },
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(adminSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Submissions')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminSubmissionsProvider),
        child: submissionsAsync.when(
          data: (subs) {
            if (subs.isEmpty) {
              return const Center(child: Text('No student submissions found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                final studentName = sub['studentId']?['fullName'] ?? 'Student';
                final hasFeedback = sub['adminFeedback'] != null && (sub['adminFeedback'] as String).isNotEmpty;
                final fileUrl = sub['fileUrl'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text('${sub['subject']} • ${sub['topic']}', style: const TextStyle(color: Colors.black54)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasFeedback ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hasFeedback ? 'Reviewed' : 'Pending Review',
                                style: TextStyle(
                                  color: hasFeedback ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      
                      // Render Image Submission from Cloudinary
                      if (fileUrl.isNotEmpty)
                        Container(
                          height: 220,
                          color: Colors.grey[200],
                          child: CachedNetworkImage(
                            imageUrl: fileUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Unable to display work snapshot', style: TextStyle(color: Colors.black54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sub['comments'] != null && (sub['comments'] as String).isNotEmpty) ...[
                              const Text('Student Comments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(sub['comments'], style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 12),
                            ],
                            if (hasFeedback) ...[
                              const Text('Your Feedback:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                              Text(sub['adminFeedback'], style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 12),
                            ],
                            ElevatedButton.icon(
                              onPressed: () => _showFeedbackDialog(sub),
                              icon: Icon(hasFeedback ? Icons.edit_outlined : Icons.rate_review_outlined),
                              label: Text(hasFeedback ? 'EDIT FEEDBACK' : 'PROVIDE FEEDBACK'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading submissions: $e')),
        ),
      ),
    );
  }
}
