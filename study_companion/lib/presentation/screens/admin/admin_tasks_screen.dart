import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';
import 'admin_dashboard.dart';

final adminTasksProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, studentId) async {
  final api = ApiClient();
  final response = await api.dio.get('/tasks');
  // Filters task list for specific student
  final allTasks = response.data as List;
  return allTasks.where((t) => t['studentId'] == studentId).toList();
});

class AdminTasksScreen extends ConsumerStatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  ConsumerState<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends ConsumerState<AdminTasksScreen> {
  final ApiClient _api = ApiClient();
  String? _selectedStudentId;

  // New task form state
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subjectController.dispose();
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

  Future<void> _assignTask() async {
    if (_selectedStudentId == null) {
      Fluttertoast.showToast(msg: "Please select a student first", backgroundColor: Colors.orange);
      return;
    }

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final subject = _subjectController.text.trim();

    if (title.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Task Title", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _api.dio.post('/tasks', data: {
        'studentId': _selectedStudentId,
        'title': title,
        'description': desc,
        'subject': subject.isNotEmpty ? subject : 'General',
        'deadline': DateFormat('yyyy-MM-dd').format(_deadline),
        'status': 'Pending',
      });

      Fluttertoast.showToast(msg: "Task Assigned Successfully!", backgroundColor: Colors.green);
      
      _titleController.clear();
      _descController.clear();
      _subjectController.clear();
      
      ref.invalidate(adminTasksProvider(_selectedStudentId!));
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to assign task: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Student Tasks')),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          final studentSelector = Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Student', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  studentsAsync.when(
                    data: (students) {
                      final approved = students.where((s) => s['status'] == 'Approved').toList();
                      if (approved.isEmpty) {
                        return const Text('No approved students found.', style: TextStyle(color: Colors.red));
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        hint: const Text('Choose student account'),
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: approved.map<DropdownMenuItem<String>>((s) {
                          return DropdownMenuItem<String>(
                            value: s['_id'],
                            child: Text(s['fullName']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStudentId = val;
                          });
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                ],
              ),
            ),
          );

          final formCard = Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create New Task', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Task Title (e.g. Watch Physics Lecture)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    maxLines: 2,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDeadline(context),
                          icon: const Icon(Icons.calendar_today_outlined, size: 16),
                          label: Text(DateFormat('yyyy-MM-dd').format(_deadline)),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _assignTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isCreating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ASSIGN TASK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );

          final tasksList = Expanded(
            child: _selectedStudentId == null
                ? const Center(child: Text('Select a student to view their tasks.'))
                : ref.watch(adminTasksProvider(_selectedStudentId!)).when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return const Center(child: Text('No tasks assigned to this student.'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Assigned Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, idx) {
                                final t = tasks[idx];
                                final status = t['status'] ?? 'Pending';
                                Color statusColor = Colors.orange;
                                if (status == 'Completed') statusColor = Colors.green;
                                if (status == 'In Progress') statusColor = Colors.blue;

                                return Card(
                                  child: ListTile(
                                    title: Text(t['title'] ?? ''),
                                    subtitle: Text('Subject: ${t['subject']} • Due: ${t['deadline']?.split('T')[0] ?? ''}'),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isPortrait
                ? Column(
                    children: [
                      studentSelector,
                      const SizedBox(height: 12),
                      formCard,
                      const SizedBox(height: 24),
                      SizedBox(height: 300, child: tasksList),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              studentSelector,
                              const SizedBox(height: 12),
                              formCard,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: tasksList,
                      )
                    ],
                  ),
          );
        },
      ),
    );
  }
}
