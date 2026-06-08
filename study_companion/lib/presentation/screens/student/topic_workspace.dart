import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/schedule_model.dart';
import '../../../core/network/api_client.dart';

class TopicWorkspace extends StatefulWidget {
  final ScheduleModel schedule;
  const TopicWorkspace({super.key, required this.schedule});

  @override
  State<TopicWorkspace> createState() => _TopicWorkspaceState();
}

class _TopicWorkspaceState extends State<TopicWorkspace> {
  final ApiClient _api = ApiClient();
  final _commentController = TextEditingController();
  String _selectedStatus = 'Pending';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.schedule.status;
    _commentController.text = widget.schedule.feedback ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    setState(() => _isSubmitting = true);
    try {
      final statusMap = {
        'Understood': 'Completed',
        'Needs Revision': 'Needs Revision',
        'Not Understood': 'Not Understood',
        'Completed': 'Completed',
      };

      final statusToSend = statusMap[_selectedStatus] ?? _selectedStatus;

      await _api.dio.patch('/schedules/${widget.schedule.id}', data: {
        'status': statusToSend,
        'feedback': _commentController.text.trim(),
      });

      Fluttertoast.showToast(msg: "Feedback submitted successfully", backgroundColor: Colors.green);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to submit feedback: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _launchURL(String urlString) async {
    String cleanedUrl = urlString.trim();
    if (cleanedUrl.isEmpty) return;

    if (!cleanedUrl.startsWith('http://') && !cleanedUrl.startsWith('https://')) {
      cleanedUrl = 'https://$cleanedUrl';
    }

    try {
      final Uri uri = Uri.parse(cleanedUrl);
      
      // Try launching in external application mode first
      final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fall back to default launching
        final bool launchedFallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!launchedFallback) {
          throw 'Could not launch URL via platform default launch mode';
        }
      }
    } catch (e) {
      // Last-resort fallback to standard launchUrl
      try {
        final Uri uri = Uri.parse(cleanedUrl);
        await launchUrl(uri);
      } catch (err) {
        Fluttertoast.showToast(
          msg: "Could not open link: $cleanedUrl\nError: $e",
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = widget.schedule.resources ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.schedule.topic)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subject: ${widget.schedule.subject}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Duration: ${widget.schedule.startTime} - ${widget.schedule.endTime}'),
                    const Divider(height: 24),
                    const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.schedule.description ?? 'No description provided.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Learning Resources', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (resources.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No resources attached to this topic.', style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              ...resources.map((res) {
                IconData resIcon = Icons.link_outlined;
                String resType = 'Web URL';
                if (res.toLowerCase().contains('youtube.com') || res.toLowerCase().contains('youtu.be')) {
                  resIcon = Icons.video_library_outlined;
                  resType = 'YouTube Video';
                } else if (res.toLowerCase().contains('.pdf')) {
                  resIcon = Icons.picture_as_pdf_outlined;
                  resType = 'PDF Document';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(resIcon, color: Theme.of(context).colorScheme.primary),
                    title: Text(res),
                    subtitle: Text(resType),
                    trailing: const Icon(Icons.open_in_new_outlined, size: 18),
                    onTap: () => _launchURL(res),
                  ),
                );
              }),
            const SizedBox(height: 24),
            Text('Your Feedback', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _feedbackButton(Icons.sentiment_very_satisfied_outlined, 'Understood', Colors.green, 'Completed'),
                _feedbackButton(Icons.sentiment_neutral_outlined, 'Needs Revision', Colors.orange, 'Needs Revision'),
                _feedbackButton(Icons.sentiment_very_dissatisfied_outlined, 'Not Understood', Colors.red, 'Not Understood'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add explanatory comments or revision notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackButton(IconData icon, String label, Color color, String value) {
    final isSelected = _selectedStatus == value || (_selectedStatus == 'Understood' && value == 'Completed') || (_selectedStatus == 'Completed' && value == 'Completed');
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: isSelected ? color : Colors.grey.withOpacity(0.4), size: 40),
          onPressed: () {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.black54,
          ),
        ),
      ],
    );
  }
}
