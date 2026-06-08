import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/app_drawer.dart';

class StudySession {
  final String subject;
  final String topic;
  final int durationSeconds;
  final DateTime date;
  final String mode;

  StudySession({
    required this.subject,
    required this.topic,
    required this.durationSeconds,
    required this.date,
    required this.mode,
  });
}

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();

  // Timer configuration
  String _selectedMode = 'Focus Session (25m)';
  int _customMinutes = 25;

  // Running timer state
  Timer? _timer;
  int _secondsElapsed = 0;
  int _secondsTarget = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _timerSet = false;

  // Study history
  static final List<StudySession> _history = [];

  @override
  void dispose() {
    _timer?.cancel();
    _subjectController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_subjectController.text.trim().isEmpty || _topicController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Subject and Topic first", backgroundColor: Colors.red);
      return;
    }

    if (!_timerSet) {
      // Configure target seconds
      if (_selectedMode == 'Focus Session (25m)') {
        _secondsTarget = 25 * 60;
      } else {
        _secondsTarget = _customMinutes * 60;
      }
      _secondsElapsed = 0;
      _timerSet = true;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsElapsed < _secondsTarget) {
          _secondsElapsed++;
        } else {
          // Timer finished
          _endSession(completed: true);
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timerSet = false;
      _secondsElapsed = 0;
    });
  }

  void _endSession({bool completed = false}) {
    _timer?.cancel();
    if (_secondsElapsed > 5) {
      // Only log sessions longer than 5 seconds to prevent spam
      final session = StudySession(
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
        durationSeconds: _secondsElapsed,
        date: DateTime.now(),
        mode: _selectedMode,
      );
      setState(() {
        _history.insert(0, session);
      });
      Fluttertoast.showToast(
        msg: completed ? "Focus session completed! Great job!" : "Session ended and saved.",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(msg: "Session discarded (too short).", backgroundColor: Colors.orange);
    }

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timerSet = false;
      _secondsElapsed = 0;
    });
  }

  String _formatTime(int elapsed, int target) {
    final remaining = target - elapsed;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      drawer: const AppDrawer(),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputsCard(),
              const SizedBox(height: 16),
              _buildTimerCard(),
              const SizedBox(height: 24),
              const Text(
                'Previous Focus Sessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildHistoryList()),
            ],
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: isPortrait 
                ? content 
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildInputsCard(),
                              const SizedBox(height: 12),
                              _buildTimerCard(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Previous Focus Sessions',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Expanded(child: _buildHistoryList()),
                          ],
                        ),
                      )
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildInputsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              enabled: !_isRunning && !_isPaused,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              enabled: !_isRunning && !_isPaused,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'Timer Mode',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Focus Session (25m)', 'Custom Session'].map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: _isRunning || _isPaused ? null : (val) {
                      setState(() {
                        _selectedMode = val!;
                      });
                    },
                  ),
                ),
                if (_selectedMode == 'Custom Session') ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: _customMinutes.toString(),
                      enabled: !_isRunning && !_isPaused,
                      decoration: const InputDecoration(
                        labelText: 'Mins',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setState(() {
                          _customMinutes = int.tryParse(val) ?? 25;
                        });
                      },
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    final elapsed = _secondsElapsed;
    final target = _timerSet 
        ? _secondsTarget 
        : (_selectedMode == 'Focus Session (25m)' ? 25 * 60 : _customMinutes * 60);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          children: [
            Text(
              _formatTime(elapsed, target),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: target > 0 ? elapsed / target : 0.0,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning)
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('START'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause_outlined),
                    label: const Text('PAUSE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 12),
                if (_timerSet)
                  OutlinedButton.icon(
                    onPressed: () => _endSession(),
                    icon: const Icon(Icons.stop_outlined),
                    label: const Text('END'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'No focus sessions recorded yet.\nStart studying to log your history!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final session = _history[index];
        final mins = session.durationSeconds ~/ 60;
        final secs = session.durationSeconds % 60;
        final timeStr = mins > 0 ? '$mins mins $secs secs' : '$secs secs';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.timer_outlined, color: Colors.green),
            title: Text('${session.subject} - ${session.topic}'),
            subtitle: Text('Mode: ${session.mode} • Duration: $timeStr'),
            trailing: Text(
              '${session.date.hour}:${session.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
