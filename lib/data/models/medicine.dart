enum ScheduleType { daily, specificDays, alternateDays }

class Medicine {
  final String id;
  final String userId;
  final String name;
  final List<String> dosagesPerDay; // e.g., ["08:00", "20:00"]
  final int remainingQuantity;
  final int initialQuantity;
  final int thresholdQuantity;

  // Advanced Scheduling Fields
  final ScheduleType scheduleType;
  final List<int> selectedDays; // 1 = Monday, 7 = Sunday
  final DateTime? startDate; // For alternate days calculation

  Medicine({
    required this.id,
    this.userId = '',
    required this.name,
    required this.dosagesPerDay,
    required this.remainingQuantity,
    required this.initialQuantity,
    this.thresholdQuantity = 2, // التنبيه عند حبتين أو أقل كما هو مطلوب
    this.scheduleType = ScheduleType.daily,
    this.selectedDays = const [],
    this.startDate,
  });

  Medicine copyWith({
    String? id,
    String? userId,
    String? name,
    List<String>? dosagesPerDay,
    int? remainingQuantity,
    int? initialQuantity,
    int? thresholdQuantity,
    ScheduleType? scheduleType,
    List<int>? selectedDays,
    DateTime? startDate,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dosagesPerDay: dosagesPerDay ?? this.dosagesPerDay,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      thresholdQuantity: thresholdQuantity ?? this.thresholdQuantity,
      scheduleType: scheduleType ?? this.scheduleType,
      selectedDays: selectedDays ?? this.selectedDays,
      startDate: startDate ?? this.startDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dosagesPerDay': dosagesPerDay,
      'remainingQuantity': remainingQuantity,
      'initialQuantity': initialQuantity,
      'thresholdQuantity': thresholdQuantity,
      'scheduleType': scheduleType.index,
      'selectedDays': selectedDays,
      'startDate': startDate?.toIso8601String(),
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map, String documentId) {
    return Medicine(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dosagesPerDay: List<String>.from(map['dosagesPerDay'] ?? []),
      remainingQuantity: map['remainingQuantity']?.toInt() ?? 0,
      initialQuantity: map['initialQuantity']?.toInt() ?? 0,
      thresholdQuantity: map['thresholdQuantity']?.toInt() ?? 2,
      scheduleType: ScheduleType.values[map['scheduleType']?.toInt() ?? 0],
      selectedDays: List<int>.from(map['selectedDays'] ?? []),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
    );
  }

  // دالة للتحقق مما إذا كان الدواء مطلوباً في تاريخ معين
  bool isScheduledForDate(DateTime date) {
    switch (scheduleType) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.specificDays:
        return selectedDays.contains(date.weekday);
      case ScheduleType.alternateDays:
        if (startDate == null) return true;
        final difference = date.difference(DateTime(startDate!.year, startDate!.month, startDate!.day)).inDays;
        return difference % 2 == 0;
    }
  }
}
