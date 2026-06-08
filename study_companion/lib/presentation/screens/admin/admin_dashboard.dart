import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/app_drawer.dart';
import '../../../core/network/api_client.dart';

final studentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/auth/students');
  return response.data;
});

final adminOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/analytics/overview');
  return Map<String, dynamic>.from(response.data);
});

final studentAnalyticsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, studentId) async {
  final api = ApiClient();
  final response = await api.dio.get('/analytics/student/$studentId');
  return Map<String, dynamic>.from(response.data);
});

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final Set<String> _expandedStudentIds = {};

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buddy Admin Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(studentsProvider);
              ref.invalidate(adminOverviewProvider);
              for (final id in _expandedStudentIds) {
                ref.invalidate(studentAnalyticsProvider(id));
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                studentsAsync.when(
                  data: (students) => _buildStats(context, students, ref, orientation),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 16),
                _buildQuickControls(context, orientation),
                const SizedBox(height: 24),
                const Text(
                  'Student Accounts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: studentsAsync.when(
                    data: (data) => _buildStudentList(context, data, ref),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/create-student').then((_) {
          ref.invalidate(studentsProvider);
        }),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<dynamic> students, WidgetRef ref, Orientation orientation) {
    final total = students.length;
    final pending = students.where((s) => s['status'] == 'Pending').length;
    final overviewAsync = ref.watch(adminOverviewProvider);

    return overviewAsync.when(
      data: (overview) {
        final totalSubmissions = overview['totalSubmissions'] ?? 0;
        final pendingReviews = overview['pendingReviews'] ?? 0;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: orientation == Orientation.portrait ? 2.2 : 3.0,
          children: [
            _statCard(context, 'Total Students', '$total', Icons.people_outline, Colors.blue),
            _statCard(context, 'Pending Access', '$pending', Icons.pending_actions_outlined, Colors.orange),
            _statCard(context, 'Submissions', '$totalSubmissions', Icons.cloud_upload_outlined, Colors.green),
            _statCard(context, 'Pending Reviews', '$pendingReviews', Icons.rate_review_outlined, Colors.red),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _statCard(context, 'Total Students', '$total', Icons.people_outline, Colors.blue),
          _statCard(context, 'Pending Access', '$pending', Icons.pending_actions_outlined, Colors.orange),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickControls(BuildContext context, Orientation orientation) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildControlCard(context, Icons.calendar_today_outlined, 'Plan Schedules', () => context.push('/admin/schedules').then((_) {
          ref.invalidate(adminOverviewProvider);
        })),
        _buildControlCard(context, Icons.menu_book_outlined, 'Link Resources', () => context.push('/admin/resources')),
        _buildControlCard(context, Icons.check_box_outlined, 'Quiz Control', () => context.push('/admin/quizzes')),
        _buildControlCard(context, Icons.cloud_upload_outlined, 'Create Submissions', () => context.push('/admin/create-submission')),
        _buildControlCard(context, Icons.rate_review_outlined, 'Reviews', () => context.push('/admin/submissions').then((_) {
          ref.invalidate(adminOverviewProvider);
          for (final id in _expandedStudentIds) {
            ref.invalidate(studentAnalyticsProvider(id));
          }
        })),
      ],
    );
  }

  Widget _buildControlCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final itemWidth = isPortrait ? (screenWidth - 42) / 2 : (screenWidth - 62) / 4;

    return SizedBox(
      width: itemWidth,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList(BuildContext context, List<dynamic> data, WidgetRef ref) {
    if (data.isEmpty) return const Center(child: Text('No students registered yet.'));

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final student = data[index];
        final isPending = student['status'] == 'Pending';
        final studentId = student['_id'];
        final isExpanded = _expandedStudentIds.contains(studentId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPending ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  child: Icon(Icons.person_outline, color: isPending ? Colors.orange : Colors.green),
                ),
                title: Text(student['fullName']),
                subtitle: Text(student['email'] ?? student['phone'] ?? ''),
                trailing: isPending
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => _approveStudent(studentId, ref),
                            child: const Text('APPROVE'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeStudent(context, studentId, student['fullName'], ref),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: Colors.green),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(isExpanded ? Icons.expand_less_outlined : Icons.expand_more_outlined),
                            onPressed: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedStudentIds.remove(studentId);
                                } else {
                                  _expandedStudentIds.add(studentId);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                onTap: isPending
                    ? null
                    : () {
                        setState(() {
                          if (isExpanded) {
                            _expandedStudentIds.remove(studentId);
                          } else {
                            _expandedStudentIds.add(studentId);
                          }
                        });
                      },
              ),
              if (!isPending && isExpanded) ...[
                const Divider(height: 1),
                _buildStudentExpandedDetails(context, studentId),
                const Divider(height: 1),
              ],
              if (!isPending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0, right: 8.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: const Text('Timetable'),
                        onPressed: () => context.push('/admin/timetable/$studentId').then((_) {
                          ref.invalidate(studentAnalyticsProvider(studentId));
                        }),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.assignment_outlined, size: 16),
                        label: const Text('Assign Task'),
                        onPressed: () => context.push('/admin/tasks').then((_) {
                          ref.invalidate(studentAnalyticsProvider(studentId));
                        }),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Parent Report'),
                        onPressed: () => _emailReport(context, studentId, student['parentEmail']),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                        onPressed: () => _removeStudent(context, studentId, student['fullName'], ref),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentExpandedDetails(BuildContext context, String studentId) {
    final analyticsAsync = ref.watch(studentAnalyticsProvider(studentId));

    return analyticsAsync.when(
      data: (data) {
        final schedulesList = data['history']?['schedules'] as List? ?? [];
        final completedSchedules = schedulesList.where((s) => s['status'] == 'Completed').toList();
        final totalMinutes = completedSchedules.fold<int>(0, (sum, item) => sum + (item['expectedDuration'] as int? ?? 0));
        final studyHours = (totalMinutes / 60).toStringAsFixed(1);

        final quizResultsList = data['history']?['quizResults'] as List? ?? [];
        final submissionsList = data['history']?['submissions'] as List? ?? [];

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Real-Time Student Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _smallMetricCard(
                      context,
                      'Study Focus',
                      '$studyHours hrs',
                      Icons.timer_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _smallMetricCard(
                      context,
                      'Completed',
                      '${completedSchedules.length}/${schedulesList.length}',
                      Icons.done_all_outlined,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _smallMetricCard(
                      context,
                      'Quiz Avg',
                      '${(data['avgQuizScore'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                      Icons.quiz_outlined,
                      Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _smallMetricCard(
                      context,
                      'Submissions',
                      '${data['submissionCount'] ?? 0}',
                      Icons.cloud_done_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (schedulesList.isNotEmpty) ...[
                const Text(
                  'Recent Timetable Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                ...schedulesList.take(3).map((session) {
                  final status = session['status'] ?? 'Pending';
                  Color statusColor = Colors.orange;
                  if (status == 'Completed') statusColor = Colors.green;
                  if (status == 'Needs Revision') statusColor = Colors.blue;
                  if (status == 'Not Understood') statusColor = Colors.red;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session['topic'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                '${session['subject']} • ${session['startTime'] ?? ''} - ${session['endTime'] ?? ''}',
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              if (session['feedback'] != null && (session['feedback'] as String).isNotEmpty)
                                Text(
                                  'Feedback: ${session['feedback']}',
                                  style: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic, fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (quizResultsList.isNotEmpty) ...[
                const Text(
                  'Recent Quiz Attempts',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                ...quizResultsList.take(2).map((res) {
                  final title = (res['quizId'] is Map) ? (res['quizId']['title'] ?? 'Study Quiz') : 'Study Quiz';
                  final score = res['score'] ?? 0;
                  final totalQ = res['totalQuestions'] ?? 0;
                  final percentage = totalQ > 0 ? (score / totalQ) * 100 : 0;
                  final date = res['createdAt']?.split('T')[0] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                'Attempted: $date • Score: $score / $totalQ',
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: percentage >= 70 ? Colors.green : (percentage >= 40 ? Colors.orange : Colors.red),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
              if (submissionsList.isNotEmpty) ...[
                const Text(
                  'Recent Proof Submissions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                ...submissionsList.take(2).map((sub) {
                  final topicName = sub['topic'] ?? '';
                  final dateStr = sub['createdAt']?.split('T')[0] ?? '';
                  final hasFeedback = sub['adminFeedback'] != null && (sub['adminFeedback'] as String).isNotEmpty;
                  final imgUrl = sub['fileUrl'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        if (imgUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topicName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                'Submitted: $dateStr',
                                style: const TextStyle(color: Colors.black54, fontSize: 11),
                              ),
                              if (hasFeedback)
                                Text(
                                  'Feedback: ${sub['adminFeedback']}',
                                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showQuickFeedbackDialog(sub),
                          child: Text(
                            hasFeedback ? 'EDIT REVIEW' : 'REVIEW',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading activity metrics: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }

  Widget _smallMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 9, color: Colors.black54),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _showQuickFeedbackDialog(dynamic sub) async {
    final controller = TextEditingController(text: sub['adminFeedback'] ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provide Review Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Topic: ${sub['topic'] ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Feedback Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final feedbackText = controller.text.trim();
      if (feedbackText.isEmpty) {
        Fluttertoast.showToast(msg: "Please type feedback comments", backgroundColor: Colors.orange);
        return;
      }

      try {
        final api = ApiClient();
        await api.dio.patch('/submissions/${sub['_id']}/feedback', data: {
          'feedback': feedbackText
        });
        Fluttertoast.showToast(msg: "Feedback submitted successfully!", backgroundColor: Colors.green);
        ref.invalidate(adminOverviewProvider);
        final String targetStudentId = (sub['studentId'] is Map) ? (sub['studentId']['_id'] ?? '') : (sub['studentId'] ?? '');
        ref.invalidate(studentAnalyticsProvider(targetStudentId));
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to save feedback: $e", backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _removeStudent(BuildContext context, String studentId, String fullName, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student Account?'),
        content: Text('Are you sure you want to permanently delete $fullName\'s account and all associated data? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ApiClient();
        await api.dio.delete('/auth/students/$studentId');
        Fluttertoast.showToast(msg: "Student removed successfully", backgroundColor: Colors.green);
        ref.invalidate(studentsProvider);
        ref.invalidate(adminOverviewProvider);
      } catch (e) {
        Fluttertoast.showToast(msg: "Failed to remove student: $e", backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _approveStudent(String id, WidgetRef ref) async {
    try {
      final api = ApiClient();
      await api.dio.patch('/auth/approve/$id');
      Fluttertoast.showToast(msg: "Student Approved!");
      ref.invalidate(studentsProvider);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _emailReport(BuildContext context, String id, String? parentEmail) async {
    if (parentEmail == null || parentEmail.isEmpty) {
      Fluttertoast.showToast(msg: "No parent email associated with this student.", backgroundColor: Colors.orange);
      return;
    }

    try {
      final api = ApiClient();
      final response = await api.dio.post('/analytics/send-report/$id');
      final result = response.data;
      
      Fluttertoast.showToast(msg: "Report generated successfully!", backgroundColor: Colors.green);
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Parent Report Summary'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emailed To: ${result['report']['parentEmail']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text('Study Time: ${result['report']['studyHours']} hours'),
                Text('Completed Topics: ${result['report']['completedTopics']}'),
                Text('Average Quiz Score: ${result['report']['avgQuizScore']}%'),
                Text('Proof Submissions: ${result['report']['submissionsCount']} submitted'),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
            ],
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to dispatch report: $e", backgroundColor: Colors.red);
    }
  }
}
