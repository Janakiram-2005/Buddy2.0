import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final studentTimetableProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, studentId) async {
  final api = ApiClient();
  final response = await api.dio.get('/schedules/all');
  final allSchedules = response.data as List;
  return allSchedules.where((s) => s['studentId']?['_id'] == studentId).toList();
});

class AdminTimetableScreen extends ConsumerStatefulWidget {
  final String studentId;
  const AdminTimetableScreen({super.key, required this.studentId});

  @override
  ConsumerState<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  final ApiClient _api = ApiClient();

  Future<void> _deleteSchedule(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this study session from the student\'s timetable?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.dio.delete('/schedules/$id');
        Fluttertoast.showToast(msg: "Study session deleted", backgroundColor: Colors.green);
        ref.invalidate(studentTimetableProvider(widget.studentId));
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to delete schedule: $e", backgroundColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(studentTimetableProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Student Timetable')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentTimetableProvider(widget.studentId)),
        child: timetableAsync.when(
          data: (schedules) {
            if (schedules.isEmpty) {
              return const Center(child: Text('No study plan sessions scheduled for this student.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final session = schedules[index];
                final dateStr = session['date']?.split('T')[0] ?? '';
                final status = session['status'] ?? 'Pending';
                Color statusColor = Colors.orange;

                if (status == 'Completed') statusColor = Colors.green;
                if (status == 'Needs Revision') statusColor = Colors.blue;
                if (status == 'Not Understood') statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text(session['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${session['subject']} • $dateStr'),
                        Text('Time: ${session['startTime']} - ${session['endTime']}'),
                        if (session['feedback'] != null && (session['feedback'] as String).isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text('Feedback: ${session['feedback']}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteSchedule(session['_id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading timetable: $e')),
        ),
      ),
    );
  }
}
