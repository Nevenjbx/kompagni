class WorkingHours {
  final int dayOfWeek; // 0-6
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final bool isClosed;
  final String? breakStartTime;
  final String? breakEndTime;

  WorkingHours({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isClosed = false,
    this.breakStartTime,
    this.breakEndTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'breakStartTime': breakStartTime,
      'breakEndTime': breakEndTime,
    };
  }

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
      isClosed: json['isClosed'] ?? false,
      breakStartTime: json['breakStartTime'],
      breakEndTime: json['breakEndTime'],
    );
  }
}
