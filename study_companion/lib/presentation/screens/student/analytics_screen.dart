import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final studentAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/analytics/student');
  return response.data;
});

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(studentAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Analytics & Progress')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(studentAnalyticsProvider),
        child: analyticsAsync.when(
          data: (data) => OrientationBuilder(
            builder: (context, orientation) {
              final isPortrait = orientation == Orientation.portrait;
              
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMetricsGrid(context, data, isPortrait),
                  const SizedBox(height: 24),
                  _buildChartCard(context, data),
                  const SizedBox(height: 24),
                  _buildRecentHistorySection(context, data),
                ],
              );

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: content,
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading analytics: $e')),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, dynamic> data, bool isPortrait) {
    final compRate = (data['completionRate'] as num?)?.toDouble() ?? 0.0;
    final avgScore = (data['avgQuizScore'] as num?)?.toDouble() ?? 0.0;
    final schedules = data['totalSchedules'] ?? 0;
    final submissions = data['submissionCount'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isPortrait ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isPortrait ? 1.4 : 1.8,
      children: [
        _metricCard(context, 'Completion Rate', '${compRate.toStringAsFixed(0)}%', Icons.check_circle_outline, Colors.green),
        _metricCard(context, 'Avg Quiz Score', '${avgScore.toStringAsFixed(0)}%', Icons.quiz_outlined, Colors.purple),
        _metricCard(context, 'Total Schedules', '$schedules', Icons.calendar_today_outlined, Colors.blue),
        _metricCard(context, 'Submissions', '$submissions', Icons.camera_alt_outlined, Colors.red),
      ],
    );
  }

  Widget _metricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, Map<String, dynamic> data) {
    final compRate = (data['completionRate'] as num?)?.toDouble() ?? 0.0;
    final avgScore = (data['avgQuizScore'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
                          String text = '';
                          switch (value.toInt()) {
                            case 0:
                              text = 'Schedule Completion';
                              break;
                            case 1:
                              text = 'Quiz Score';
                              break;
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: compRate,
                          color: Theme.of(context).colorScheme.primary,
                          width: 32,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: avgScore,
                          color: Theme.of(context).colorScheme.secondary,
                          width: 32,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
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

  Widget _buildRecentHistorySection(BuildContext context, Map<String, dynamic> data) {
    final history = data['history'] ?? {};
    final schedules = (history['schedules'] as List?)?.take(3).toList() ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recent Schedules Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No study schedules recorded yet.', style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ...schedules.map((s) {
                final status = s['status'] ?? 'Pending';
                Color iconColor = Colors.orange;
                IconData icon = Icons.pending_actions_outlined;

                if (status == 'Completed') {
                  iconColor = Colors.green;
                  icon = Icons.check_circle_outline;
                } else if (status == 'Needs Revision') {
                  iconColor = Colors.blue;
                  icon = Icons.cached_outlined;
                } else if (status == 'Not Understood') {
                  iconColor = Colors.red;
                  icon = Icons.error_outline;
                }

                return ListTile(
                  leading: Icon(icon, color: iconColor),
                  title: Text(s['topic'] ?? ''),
                  subtitle: Text(s['subject'] ?? ''),
                  trailing: Text(status, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
