import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../data/models/schedule_model.dart';

final scheduleProvider = FutureProvider<List<ScheduleModel>>((ref) async {
  final api = ApiClient();
  final response = await api.dio.get('/schedules');
  return (response.data as List).map((e) => ScheduleModel.fromJson(e)).toList();
});
