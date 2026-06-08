import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final studentTasksProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/tasks');
  return response.data;
});

class TaskManagementScreen extends ConsumerStatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  ConsumerState<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends ConsumerState<TaskManagementScreen> {
  final ApiClient _api = ApiClient();

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _api.dio.patch('/tasks/$id', data: {'status': status});
      Fluttertoast.showToast(msg: "Task status updated to $status", backgroundColor: Colors.green);
      ref.invalidate(studentTasksProvider);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to update task: $e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(studentTasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Study Tasks')),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return tasksAsync.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Center(child: Text('No study tasks assigned yet.'));
              }

              // Calculate completion percentage
              final completed = tasks.where((t) => t['status'] == 'Completed').length;
              final progress = tasks.isNotEmpty ? (completed / tasks.length) * 100 : 0.0;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Text(
                              'Task Completion Rate',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress / 100.0,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                              backgroundColor: Colors.grey.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${progress.toStringAsFixed(0)}% Completed ($completed/${tasks.length} tasks)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final id = task['_id'];
                          final title = task['title'] ?? 'Study Task';
                          final desc = task['description'] ?? '';
                          final subject = task['subject'] ?? 'General';
                          final status = task['status'] ?? 'Pending';

                          IconData statusIcon = Icons.hourglass_empty_outlined;
                          Color statusColor = Colors.orange;

                          if (status == 'In Progress') {
                            statusIcon = Icons.cached_outlined;
                            statusColor = Colors.blue;
                          } else if (status == 'Completed') {
                            statusIcon = Icons.check_circle_outline;
                            statusColor = Colors.green;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                              child: ListTile(
                                leading: Icon(statusIcon, color: statusColor, size: 28),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (desc.isNotEmpty) Text(desc),
                                    const SizedBox(height: 4),
                                    Text('Subject: $subject', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                trailing: DropdownButton<String>(
                                  value: status,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onChanged: (newVal) {
                                    if (newVal != null && newVal != status) {
                                      _updateStatus(id, newVal);
                                    }
                                  },
                                  items: ['Pending', 'In Progress', 'Completed'].map((s) {
                                    return DropdownMenuItem(
                                      value: s,
                                      child: Text(s, style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading tasks: $e')),
          );
        },
      ),
    );
  }
}
