import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/network/api_client.dart';

class SubmissionScreen extends StatefulWidget {
  const SubmissionScreen({super.key});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  File? _image;
  final _picker = ImagePicker();
  final ApiClient _api = ApiClient();
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _commentsController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera, // RESTRICTED TO CAMERA ONLY AS REQUESTED
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Camera access error: $e", backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proof of Study')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Capture your work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Only direct camera photos are accepted for authenticity.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Optional Comments',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.withOpacity(0.05),
              ),
              child: _image == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _takePicture,
                            child: const Text('OPEN CAMERA'),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 24),
            if (_image != null) ...[
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadSubmission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SUBMIT NOW', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _takePicture,
                child: const Text('RETAKE PHOTO'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _uploadSubmission() async {
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();

    if (subject.isEmpty || topic.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter Subject and Topic", backgroundColor: Colors.orange);
      return;
    }

    if (_image == null) {
      Fluttertoast.showToast(msg: "Please capture a photo of your study proof first", backgroundColor: Colors.orange);
      return;
    }

    setState(() => _isUploading = true);
    try {
      // Convert captured image file to base64
      final bytes = await _image!.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      await _api.dio.post('/submissions', data: {
        'subject': subject,
        'topic': topic,
        'submissionType': 'Image',
        'imageBase64': base64Image,
        'comments': _commentsController.text.trim(),
      });

      Fluttertoast.showToast(msg: "Submission Successful!", backgroundColor: Colors.green);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: "Submission failed: $e", backgroundColor: Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
