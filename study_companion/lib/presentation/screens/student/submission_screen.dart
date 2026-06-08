import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/network/api_client.dart';

final studentRequirementsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/submission-requirements');
  return response.data as List;
});

final studentSubmissionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/submissions');
  return response.data as List;
});

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  final _picker = ImagePicker();

  // Active Submission form state
  dynamic _selectedRequirement; // null means ad-hoc submission
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _commentsController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  void _startSubmission(dynamic req) {
    setState(() {
      _selectedRequirement = req;
      if (req != null) {
        _subjectController.text = req['subject'] ?? '';
        _topicController.text = req['topic'] ?? '';
      } else {
        _subjectController.clear();
        _topicController.clear();
      }
      _commentsController.clear();
      _image = null;
      _showForm = true;
    });
  }

  void _cancelSubmission() {
    setState(() {
      _showForm = false;
      _selectedRequirement = null;
      _image = null;
    });
  }

  Future<void> _takePicture() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Camera access error: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _uploadSubmission() async {
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();

    if (subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Subject and Topic", backgroundColor: Colors.orange);
      return;
    }

    if (_image == null) {
      Fluttertoast.showToast(msg: "Please capture a photo of your study proof first", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isUploading = true);
    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final payload = {
        'subject': subject,
        'topic': topic,
        'submissionType': 'Image',
        'imageBase64': base64Image,
        'comments': _commentsController.text.trim(),
        if (_selectedRequirement != null) 'requirementId': _selectedRequirement['_id'],
      };

      await _api.dio.post('/submissions', data: payload);

      Fluttertoast.showToast(msg: "Submission Successful!", backgroundColor: Colors.green);
      
      // Invalidate providers to refresh
      ref.invalidate(studentRequirementsProvider);
      ref.invalidate(studentSubmissionsProvider);

      setState(() {
        _showForm = false;
        _image = null;
        _selectedRequirement = null;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Submission failed: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requirementsAsync = ref.watch(studentRequirementsProvider);
    final submissionsAsync = ref.watch(studentSubmissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        bottom: _showForm
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.assignment_late_outlined), text: 'Pending Tasks'),
                  Tab(icon: Icon(Icons.history_outlined), text: 'History'),
                ],
              ),
      ),
      body: _showForm
          ? _buildSubmissionForm()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequirementsTab(requirementsAsync),
                _buildHistoryTab(submissionsAsync),
              ],
            ),
      floatingActionButton: _showForm
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _startSubmission(null),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Ad-hoc Submit'),
            ),
    );
  }

  Widget _buildRequirementsTab(AsyncValue<List<dynamic>> requirementsAsync) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentRequirementsProvider),
      child: requirementsAsync.when(
        data: (reqs) {
          final pending = reqs.where((r) => r['status'] == 'Pending' || r['status'] == 'Rejected').toList();
          if (pending.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No pending submission requirements!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('All assigned work has been submitted.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, idx) {
              final r = pending[idx];
              final deadlineStr = r['deadline'] != null ? r['deadline'].split('T')[0] : 'No deadline';
              final isRejected = r['status'] == 'Rejected';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRejected ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRejected ? 'Needs Revision' : 'Pending',
                              style: TextStyle(
                                color: isRejected ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text('Due: $deadlineStr', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(r['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Subject: ${r['subject']} • Topic: ${r['topic']}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                      if (r['description'] != null && (r['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(r['description'], style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                      const Divider(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _startSubmission(r),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('SUBMIT WORK NOW'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading requirements: $e')),
      ),
    );
  }

  Widget _buildHistoryTab(AsyncValue<List<dynamic>> submissionsAsync) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentSubmissionsProvider),
      child: submissionsAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No submissions found.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Your uploaded proof history will appear here.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            itemBuilder: (context, idx) {
              final s = subs[idx];
              final dateStr = s['submittedAt'] != null ? s['submittedAt'].split('T')[0] : '';
              final hasFeedback = s['adminFeedback'] != null && (s['adminFeedback'] as String).isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text(s['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${s['subject']} • Submitted: $dateStr'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasFeedback ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hasFeedback ? 'Reviewed' : 'Pending',
                          style: TextStyle(
                            color: hasFeedback ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    if (s['fileUrl'] != null)
                      CachedNetworkImage(
                        imageUrl: s['fileUrl'],
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (s['comments'] != null && (s['comments'] as String).isNotEmpty) ...[
                            Text('Your comments: ${s['comments']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                          if (hasFeedback) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.feedback_outlined, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Admin Feedback: ${s['adminFeedback']}',
                                      style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildSubmissionForm() {
    final title = _selectedRequirement != null
        ? 'Submit Work: ${_selectedRequirement['title']}'
        : 'Submit Custom Work';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: _cancelSubmission, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _subjectController,
            enabled: _selectedRequirement == null,
            decoration: const InputDecoration(
              labelText: 'Subject',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.book_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            enabled: _selectedRequirement == null,
            decoration: const InputDecoration(
              labelText: 'Topic',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentsController,
            decoration: const InputDecoration(
              labelText: 'Optional Comments',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.comment_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.withOpacity(0.05),
            ),
            child: _image == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _takePicture,
                          child: const Text('OPEN CAMERA'),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
          ),
          const SizedBox(height: 24),
          if (_image != null) ...[
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SUBMIT NOW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _takePicture,
              child: const Text('RETAKE PHOTO'),
            ),
          ],
        ],
      ),
    );
  }
}
