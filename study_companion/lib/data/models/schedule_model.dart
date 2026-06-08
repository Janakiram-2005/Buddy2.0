class ScheduleModel {
  final String id;
  final String subject;
  final String topic;
  final String startTime;
  final String endTime;
  final String status;
  final String? description;
  final String? feedback;
  final List<String>? resources;

  ScheduleModel({
    required this.id,
    required this.subject,
    required this.topic,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.description,
    this.feedback,
    this.resources,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['_id'],
      subject: json['subject'],
      topic: json['topic'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      status: json['status'],
      description: json['description'],
      feedback: json['feedback'],
      resources: json['resources'] != null ? List<String>.from(json['resources']) : null,
    );
  }
}
