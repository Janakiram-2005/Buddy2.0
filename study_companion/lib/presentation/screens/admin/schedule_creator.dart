import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Bulk Table Importer State
  final List<Map<String, String>> _tableRows = [];
  bool _isBulkPublishing = false;

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

  void _showCsvTemplateDialog() {
    const csvContent = "Subject,Topic,Date (YYYY-MM-DD),Start Time (HH:MM),End Time (HH:MM),Expected Duration (minutes),Description\n"
        "Mathematics,Calculus Limits,2026-06-10,09:00,11:00,120,Review limits and continuity\n"
        "Physics,Newtonian Mechanics,2026-06-10,13:00,14:30,90,Solve chapter 3 exercises\n"
        "Chemistry,Organic Reactions,2026-06-11,10:00,12:00,120,Understand mechanisms";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Template Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Copy this template text, modify in Excel, and paste it back into the Paste tab to import in bulk.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SingleChildScrollView(
                child: SelectableText(
                  csvContent,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_outlined, size: 16),
            label: const Text('COPY TEMPLATE'),
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: csvContent));
              Fluttertoast.showToast(msg: "CSV Template copied to clipboard!");
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showPasteCsvDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste CSV Spreadsheet Rows'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Paste comma-separated rows. Expected format:\nSubject,Topic,Date (YYYY-MM-DD),StartTime,EndTime,Duration,Description',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Mathematics,Integration,2026-06-10,09:00,11:00,120,Review basic formulas',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _importCsvText(controller.text);
            },
            child: const Text('IMPORT ROWS'),
          ),
        ],
      ),
    );
  }

  void _importCsvText(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return;

    List<Map<String, String>> newRows = [];
    int startIndex = 0;
    // Skip headers if present
    if (lines[0].toLowerCase().contains('subject') || lines[0].toLowerCase().contains('topic')) {
      startIndex = 1;
    }

    for (int i = startIndex; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length >= 2) {
        newRows.add({
          'subject': parts[0].trim(),
          'topic': parts[1].trim(),
          'date': parts.length > 2 ? parts[2].trim() : DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'startTime': parts.length > 3 ? parts[3].trim() : '09:00',
          'endTime': parts.length > 4 ? parts[4].trim() : '11:00',
          'duration': parts.length > 5 ? parts[5].trim() : '120',
          'description': parts.length > 6 ? parts.sublist(6).join(',').trim() : '',
        });
      }
    }

    if (newRows.isNotEmpty) {
      setState(() {
        _tableRows.addAll(newRows);
      });
      Fluttertoast.showToast(msg: "Imported ${newRows.length} rows into the table!", backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(msg: "No valid rows found in pasted text.", backgroundColor: Colors.orange);
    }
  }

  Future<void> _publishBulkSchedules() async {
    if (_selectedStudentId == null) {
      Fluttertoast.showToast(msg: "Please select a student first", backgroundColor: Colors.orange);
      return;
    }

    final validRows = _tableRows.where((row) => row['subject']!.trim().isNotEmpty && row['topic']!.trim().isNotEmpty).toList();
    if (validRows.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill in Subject and Topic for at least one row", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isBulkPublishing = true);
    int successCount = 0;
    for (final row in validRows) {
      try {
        await _api.dio.post('/schedules', data: {
          'studentId': _selectedStudentId,
          'date': row['date']!.trim(),
          'startTime': row['startTime']!.trim(),
          'endTime': row['endTime']!.trim(),
          'subject': row['subject']!.trim(),
          'topic': row['topic']!.trim(),
          'description': row['description']!.trim(),
          'expectedDuration': int.tryParse(row['duration']!) ?? 120,
          'resources': [],
        });
        successCount++;
      } catch (e) {
        print("Error publishing row: $e");
      }
    }

    setState(() => _isBulkPublishing = false);
    if (successCount > 0) {
      Fluttertoast.showToast(msg: "Successfully published $successCount study sessions!", backgroundColor: Colors.green);
      setState(() {
        _tableRows.clear();
      });
    } else {
      Fluttertoast.showToast(msg: "Failed to publish study sessions. Check API logs.", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schedules')),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Student Selector
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Target Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 6),
                  studentsAsync.when(
                    data: (students) {
                      final approved = students.where((s) => s['status'] == 'Approved').toList();
                      if (approved.isEmpty) {
                        return const Text('No approved students available.', style: TextStyle(color: Colors.red));
                      }
                      return DropdownButtonFormField<String>(
                        value: _selectedStudentId,
                        hint: const Text('Choose Student'),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
            const SizedBox(height: 12),

            // Tab bar switcher
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.edit_outlined), text: 'Manual'),
                Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'AI Generator'),
                Tab(icon: Icon(Icons.table_chart_outlined), text: 'Spreadsheet Grid'),
              ],
            ),

            // Tab contents
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Manual form
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildManualFormCard(context),
                  ),

                  // Tab 2: AI Planner
                  OrientationBuilder(
                    builder: (context, orientation) {
                      final isPortrait = orientation == Orientation.portrait;
                      final aiInput = _buildAiPromptCard();
                      final aiOutput = _buildAiOutputList();

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: isPortrait
                            ? SingleChildScrollView(
                                child: Column(
                                  children: [
                                    aiInput,
                                    const SizedBox(height: 16),
                                    SizedBox(height: 350, child: aiOutput),
                                  ],
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 1, child: SingleChildScrollView(child: aiInput)),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 1, child: aiOutput),
                                ],
                              ),
                      );
                    },
                  ),

                  // Tab 3: Spreadsheet/CSV Grid importer
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTableGridTab(),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildAiOutputList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Generated Schedule Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_generatedItems.isEmpty)
          const Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: Text('AI study schedules will appear here.', style: TextStyle(fontStyle: FontStyle.italic))),
              ),
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

  Widget _buildTableGridTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy CSV Template'),
              onPressed: _showCsvTemplateDialog,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Paste/Import CSV'),
              onPressed: _showPasteCsvDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_outlined, size: 18),
              label: const Text('Add Row'),
              onPressed: () {
                setState(() {
                  _tableRows.add({
                    'subject': '',
                    'topic': '',
                    'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'startTime': '09:00',
                    'endTime': '11:00',
                    'duration': '120',
                    'description': '',
                  });
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _tableRows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No rows in the spreadsheet yet.\nAdd rows manually or paste CSV data from Excel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary.withOpacity(0.08)),
                      columns: const [
                        DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Topic', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Date (YYYY-MM-DD)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Start (HH:MM)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('End (HH:MM)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Mins', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: List<DataRow>.generate(
                        _tableRows.length,
                        (index) {
                          final row = _tableRows[index];
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 120,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Subject'),
                                    controller: TextEditingController(text: row['subject'])..selection = TextSelection.collapsed(offset: row['subject']!.length),
                                    onChanged: (val) => row['subject'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 140,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Topic'),
                                    controller: TextEditingController(text: row['topic'])..selection = TextSelection.collapsed(offset: row['topic']!.length),
                                    onChanged: (val) => row['topic'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'YYYY-MM-DD'),
                                    controller: TextEditingController(text: row['date'])..selection = TextSelection.collapsed(offset: row['date']!.length),
                                    onChanged: (val) => row['date'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'HH:MM'),
                                    controller: TextEditingController(text: row['startTime'])..selection = TextSelection.collapsed(offset: row['startTime']!.length),
                                    onChanged: (val) => row['startTime'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'HH:MM'),
                                    controller: TextEditingController(text: row['endTime'])..selection = TextSelection.collapsed(offset: row['endTime']!.length),
                                    onChanged: (val) => row['endTime'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: '120'),
                                    controller: TextEditingController(text: row['duration'])..selection = TextSelection.collapsed(offset: row['duration']!.length),
                                    onChanged: (val) => row['duration'] = val,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Description'),
                                    controller: TextEditingController(text: row['description'])..selection = TextSelection.collapsed(offset: row['description']!.length),
                                    onChanged: (val) => row['description'] = val,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _tableRows.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        if (_tableRows.isNotEmpty)
          ElevatedButton(
            onPressed: _isBulkPublishing ? null : _publishBulkSchedules,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isBulkPublishing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('PUBLISH BULK SCHEDULES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
