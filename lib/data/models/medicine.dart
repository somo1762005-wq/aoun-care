class Medicine {
  final String id;
  final String name;
  final List<String> dosagesPerDay; // e.g., ["08:00", "20:00"]
  final int remainingQuantity;
  final int initialQuantity;
  final int thresholdQuantity;

  Medicine({
    required this.id,
    required this.name,
    required this.dosagesPerDay,
    required this.remainingQuantity,
    required this.initialQuantity,
    this.thresholdQuantity = 3,
  });

  Medicine copyWith({
    String? id,
    String? name,
    List<String>? dosagesPerDay,
    int? remainingQuantity,
    int? initialQuantity,
    int? thresholdQuantity,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dosagesPerDay: dosagesPerDay ?? this.dosagesPerDay,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      thresholdQuantity: thresholdQuantity ?? this.thresholdQuantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosagesPerDay': dosagesPerDay,
      'remainingQuantity': remainingQuantity,
      'initialQuantity': initialQuantity,
      'thresholdQuantity': thresholdQuantity,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map, String documentId) {
    return Medicine(
      id: documentId,
      name: map['name'] ?? '',
      dosagesPerDay: List<String>.from(map['dosagesPerDay'] ?? []),
      remainingQuantity: map['remainingQuantity']?.toInt() ?? 0,
      initialQuantity: map['initialQuantity']?.toInt() ?? 0,
      thresholdQuantity: map['thresholdQuantity']?.toInt() ?? 3,
    );
  }
}
