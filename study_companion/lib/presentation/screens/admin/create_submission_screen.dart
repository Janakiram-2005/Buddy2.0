import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';
import 'admin_dashboard.dart';

class CreateSubmissionScreen extends ConsumerStatefulWidget {
  const CreateSubmissionScreen({super.key});

  @override
  ConsumerState<CreateSubmissionScreen> createState() => _CreateSubmissionScreenState();
}

class _CreateSubmissionScreenState extends ConsumerState<CreateSubmissionScreen> {
  final ApiClient _api = ApiClient();
  String? _selectedStudentId;

  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 2));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _createRequirement() async {
    if (_selectedStudentId == null) {
      Fluttertoast.showToast(msg: "Please select a student", backgroundColor: Colors.orange);
      return;
    }

    final title = _titleController.text.trim();
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();
    final desc = _descriptionController.text.trim();

    if (title.isEmpty || subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Title, Subject, and Topic are required", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _api.dio.post('/submission-requirements', data: {
        'studentId': _selectedStudentId,
        'title': title,
        'subject': subject,
        'topic': topic,
        'description': desc,
        'deadline': DateFormat('yyyy-MM-dd').format(_deadline),
      });

      Fluttertoast.showToast(msg: "Submission Requirement Created!", backgroundColor: Colors.green);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to create: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Submission Task')),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Assign a Submission Target',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Student dropdown selection
                    studentsAsync.when(
                      data: (students) {
                        final approved = students.where((s) => s['status'] == 'Approved').toList();
                        return DropdownButtonFormField<String>(
                          value: _selectedStudentId,
                          hint: const Text('Select Student'),
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: approved.map<DropdownMenuItem<String>>((s) {
                            return DropdownMenuItem<String>(
                              value: s['_id'],
                              child: Text(s['fullName']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedStudentId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading students: $e'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Submission Title (e.g. Chapter 3 Calculus Proofs)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _topicController,
                            decoration: const InputDecoration(
                              labelText: 'Topic',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Submission Guidelines (e.g. upload pdf/screenshot of solutions)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deadline Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                        OutlinedButton.icon(
                          onPressed: () => _selectDeadline(context),
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(DateFormat('yyyy-MM-dd').format(_deadline)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _createRequirement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREATE SUBMISSION REQUIREMENT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
