import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../providers/ai_provider.dart';
import '../../../core/network/api_client.dart';
import '../admin/admin_dashboard.dart';

class ScheduleCreator extends ConsumerStatefulWidget {
  const ScheduleCreator({super.key});

  @override
  ConsumerState<ScheduleCreator> createState() => _ScheduleCreatorState();
}

class _ScheduleCreatorState extends ConsumerState<ScheduleCreator> {
  final ApiClient _api = ApiClient();

  // Selected Student
  String? _selectedStudentId;

  // AI Generator state
  final _promptController = TextEditingController();
  List<dynamic> _generatedItems = [];
  bool _isLoading = false;

  // Manual Form State
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  final _durationController = TextEditingController(text: '120');
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void dispose() {
    _promptController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _generateAI() async {
    if (_selectedStudentId == null) {
      Fluttertoast.showToast(msg: "Please select a student first", backgroundColor: Colors.orange);
      return;
    }

    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter a study prompt", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ref.read(aiProvider).generateSchedule(prompt);
      setState(() {
        _generatedItems = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: "AI Generation failed: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _publishManualSchedule() async {
    if (_selectedStudentId == null) {
      Fluttertoast.showToast(msg: "Please select a student first", backgroundColor: Colors.orange);
      return;
    }

    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();
    final desc = _descController.text.trim();

    if (subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Subject and Topic", backgroundColor: Colors.orange);
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    try {
      await _api.dio.post('/schedules', data: {
        'studentId': _selectedStudentId,
        'date': formattedDate,
        'startTime': startStr,
        'endTime': endStr,
        'subject': subject,
        'topic': topic,
        'description': desc,
        'expectedDuration': int.tryParse(_durationController.text) ?? 120,
        'resources': [],
      });

      Fluttertoast.showToast(msg: "Schedule Published Successfully!", backgroundColor: Colors.green);
      _subjectController.clear();
      _topicController.clear();
      _descController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to publish schedule: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _publishAiSchedule(dynamic item) async {
    try {
      final formattedDate = item['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _api.dio.post('/schedules', data: {
        'studentId': _selectedStudentId,
        'date': formattedDate,
        'startTime': item['startTime'] ?? '09:00',
        'endTime': item['endTime'] ?? '11:00',
        'subject': item['subject'] ?? 'General',
        'topic': item['topic'] ?? 'Topic',
        'description': item['description'] ?? '',
        'expectedDuration': item['expectedDuration'] ?? 120,
        'resources': [],
      });
      Fluttertoast.showToast(msg: "Published: ${item['topic']}", backgroundColor: Colors.green);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to publish: $e", backgroundColor: Colors.red);
    }
  }

  Future<void> _publishAllAiSchedules() async {
    if (_generatedItems.isEmpty) return;
    
    int successCount = 0;
    for (var item in _generatedItems) {
      try {
        final formattedDate = item['date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
        await _api.dio.post('/schedules', data: {
          'studentId': _selectedStudentId,
          'date': formattedDate,
          'startTime': item['startTime'] ?? '09:00',
          'endTime': item['endTime'] ?? '11:00',
          'subject': item['subject'] ?? 'General',
          'topic': item['topic'] ?? 'Topic',
          'description': item['description'] ?? '',
          'expectedDuration': item['expectedDuration'] ?? 120,
          'resources': [],
        });
        successCount++;
      } catch (_) {}
    }
    Fluttertoast.showToast(msg: "Published $successCount schedules!", backgroundColor: Colors.green);
    setState(() {
      _generatedItems = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schedules')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;

          final studentSelector = Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Target Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  studentsAsync.when(
                    data: (students) {
                      final approved = students.where((s) => s['status'] == 'Approved').toList();
                      if (approved.isEmpty) {
                        return const Text('No approved students available.', style: TextStyle(color: Colors.red));
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        hint: const Text('Choose Student'),
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
                    error: (e, _) => Text('Error loading students: $e'),
                  ),
                ],
              ),
            ),
          );

          final creatorForms = Column(
            children: [
              _buildAiPromptCard(),
              const SizedBox(height: 16),
              _buildManualFormCard(context),
            ],
          );

          final aiOutputList = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Generated Schedule Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_generatedItems.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('AI study schedules will appear here.', style: TextStyle(fontStyle: FontStyle.italic))),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _generatedItems.length,
                    itemBuilder: (context, index) {
                      final item = _generatedItems[index];
                      return Card(
                        child: ListTile(
                          title: Text(item['topic'] ?? ''),
                          subtitle: Text('${item['subject']} • ${item['date']} • ${item['startTime']}-${item['endTime']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () => _publishAiSchedule(item),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _publishAllAiSchedules,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('PUBLISH ALL GENERATED ITEMS'),
                ),
              ]
            ],
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isPortrait
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        studentSelector,
                        const SizedBox(height: 16),
                        creatorForms,
                        const SizedBox(height: 24),
                        SizedBox(height: 350, child: aiOutputList),
                      ],
                    ),
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
                              creatorForms,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: aiOutputList,
                      )
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAiPromptCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.purple),
                SizedBox(width: 8),
                Text('AI Study Plan Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'AI Prompt / Request',
                hintText: 'e.g., Create a 3-day study plan for organic chemistry focus',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateAI,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GENERATE WITH AI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFormCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Create Schedule Manually', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(labelText: 'Topic', border: OutlineInputBorder()),
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
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: const InputDecoration(labelText: 'Mins Duration', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, true),
                    icon: const Icon(Icons.timer_outlined, size: 16),
                    label: Text('Start: ${_startTime.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, false),
                    icon: const Icon(Icons.timer_off_outlined, size: 16),
                    label: Text('End: ${_endTime.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _publishManualSchedule,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('PUBLISH SCHEDULE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
