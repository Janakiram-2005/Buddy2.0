import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/app_drawer.dart';
import './task_management_screen.dart';
import './quiz_list_screen.dart';
import './topic_workspace.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(scheduleProvider);
    final tasks = ref.watch(studentTasksProvider);
    final quizzes = ref.watch(studentQuizzesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Buddy Student Hub')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scheduleProvider);
          ref.invalidate(studentTasksProvider);
          ref.invalidate(studentQuizzesProvider);
        },
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;
            
            final mainContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // TODAY'S STUDY PLAN
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Study Plan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_outlined),
                      onPressed: () => ref.invalidate(scheduleProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                schedules.when(
                  data: (data) => _buildScheduleList(context, data),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading schedules: $e'),
                ),
                const SizedBox(height: 24),

                // QUICK ACTIONS
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context, orientation),
                const SizedBox(height: 24),

                // TASKS & QUIZZES (Stack vertically in portrait, side-by-side in landscape)
                if (isPortrait) ...[
                  _buildTasksSection(context, tasks),
                  const SizedBox(height: 24),
                  _buildQuizzesSection(context, quizzes),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTasksSection(context, tasks)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildQuizzesSection(context, quizzes)),
                    ],
                  ),
                const SizedBox(height: 48),
              ],
            );

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: mainContent,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, color: Theme.of(context).colorScheme.secondary, size: 36),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Motivation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  '"Success is the sum of small efforts, repeated day in and day out."',
                  style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context, List<dynamic> items) {
    if (items.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 36),
                SizedBox(height: 12),
                Text('No study sessions scheduled for today.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final status = item.status;
        Color statusColor = Colors.orange;
        if (status == 'Completed') statusColor = Colors.green;
        if (status == 'Needs Revision') statusColor = Colors.blue;
        if (status == 'Not Understood') statusColor = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.book_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(item.topic, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${item.subject} • ${item.startTime} - ${item.endTime}'),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TopicWorkspace(schedule: item)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, Orientation orientation) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: orientation == Orientation.portrait ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: orientation == Orientation.portrait ? 1.5 : 2.0,
      children: [
        _buildActionCard(context, Icons.timer_outlined, 'Focus Timer', Colors.green, () => context.push('/timer')),
        _buildActionCard(context, Icons.quiz_outlined, 'Quizzes', Colors.purple, () => context.push('/quiz-list')),
        _buildActionCard(context, Icons.camera_alt_outlined, 'Submit Proof', Colors.blue, () => context.push('/submit')),
        _buildActionCard(context, Icons.settings_outlined, 'Settings', Colors.grey, () => context.push('/settings')),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, AsyncValue<List<dynamic>> tasksAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pending Tasks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => context.push('/tasks'),
                  child: const Text('View All'),
                )
              ],
            ),
            const Divider(),
            tasksAsync.when(
              data: (data) {
                final pending = data.where((t) => t['status'] != 'Completed').toList();
                if (pending.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('All tasks completed! Great work!', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pending.length > 3 ? 3 : pending.length,
                  itemBuilder: (context, idx) {
                    final t = pending[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.assignment_outlined, color: Colors.blue),
                      title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(t['subject'] ?? 'General'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesSection(BuildContext context, AsyncValue<List<dynamic>> quizzesAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Quizzes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () => context.push('/quiz-list'),
                  child: const Text('View All'),
                )
              ],
            ),
            const Divider(),
            quizzesAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('No quizzes scheduled.', style: TextStyle(fontStyle: FontStyle.italic)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length > 3 ? 3 : data.length,
                  itemBuilder: (context, idx) {
                    final q = data[idx];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.quiz_outlined, color: Colors.purple),
                      title: Text(q['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(q['subject'] ?? ''),
                      onTap: () => context.push('/quiz-attempt/${q['_id']}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            )
          ],
        ),
      ),
    );
  }
}
