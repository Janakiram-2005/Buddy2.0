import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_drawer.dart';

final adminSchedulesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/schedules/all');
  return response.data;
});

class ResourceManagementScreen extends ConsumerStatefulWidget {
  const ResourceManagementScreen({super.key});

  @override
  ConsumerState<ResourceManagementScreen> createState() => _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends ConsumerState<ResourceManagementScreen> {
  final ApiClient _api = ApiClient();

  Future<void> _addResource(dynamic schedule) async {
    final controller = TextEditingController();
    List<String> tempUrls = List<String>.from(schedule['resources'] ?? []);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Manage Learning Resources'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Topic: ${schedule['topic']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Resource URL (YouTube/PDF/Image)',
                          hintText: 'https://...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 28),
                      onPressed: () {
                        final val = controller.text.trim();
                        if (val.isNotEmpty) {
                          setDialogState(() {
                            tempUrls.add(val);
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Resources in this batch:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  maxHeight: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: tempUrls.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No resources added yet.', style: TextStyle(fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: tempUrls.length,
                          itemBuilder: (c, idx) {
                            final url = tempUrls[idx];
                            return ListTile(
                              dense: true,
                              title: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                onPressed: () {
                                  setDialogState(() {
                                    tempUrls.removeAt(idx);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('SAVE ALL'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      try {
        await _api.dio.patch('/schedules/${schedule['_id']}', data: {
          'resources': tempUrls,
        });
        Fluttertoast.showToast(msg: "Resources updated successfully", backgroundColor: Colors.green);
        ref.invalidate(adminSchedulesProvider);
      } catch (e) {
        Fluttertoast.showToast(msg: "Error saving resources: $e", backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _removeResource(dynamic schedule, int resIndex) async {
    List<dynamic> currentResources = List.from(schedule['resources'] ?? []);
    currentResources.removeAt(resIndex);

    try {
      await _api.dio.patch('/schedules/${schedule['_id']}', data: {
        'resources': currentResources,
      });
      Fluttertoast.showToast(msg: "Resource removed", backgroundColor: Colors.green);
      ref.invalidate(adminSchedulesProvider);
    } catch (e) {
      Fluttertoast.showToast(msg: "Error removing resource: $e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(adminSchedulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Study Resources')),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminSchedulesProvider),
        child: schedulesAsync.when(
          data: (schedules) {
            if (schedules.isEmpty) {
              return const Center(child: Text('No active schedules found. Create schedules to attach resources.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                final resources = schedule['resources'] as List? ?? [];
                final studentName = schedule['studentId']?['fullName'] ?? 'General';

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
                            Text(
                              '${schedule['subject']} (${studentName})',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_link_outlined, color: Colors.green),
                              onPressed: () => _addResource(schedule),
                            )
                          ],
                        ),
                        Text(
                          schedule['topic'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (resources.isEmpty)
                          const Text('No resources linked.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54))
                        else ...[
                          const SizedBox(height: 8),
                          const Text('Linked Resources:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          ...List.generate(resources.length, (idx) {
                            final res = resources[idx];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.link_outlined),
                              title: Text(res, style: const TextStyle(fontSize: 13)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => _removeResource(schedule, idx),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading schedules: $e')),
        ),
      ),
    );
  }
}
