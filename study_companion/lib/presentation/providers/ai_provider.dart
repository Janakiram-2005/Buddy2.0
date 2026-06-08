import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

final aiProvider = Provider((ref) => AiService());

class AiService {
  final _api = ApiClient();

  Future<List<dynamic>> generateSchedule(String prompt) async {
    final response = await _api.dio.post('/ai/generate-schedule', data: {'prompt': prompt});
    return response.data;
  }

  Future<Map<String, dynamic>> generateQuiz(String subject, String topic, int count) async {
    final response = await _api.dio.post('/ai/generate-quiz', data: {
      'subject': subject,
      'topic': topic,
      'count': count,
    });
    return response.data;
  }
}
