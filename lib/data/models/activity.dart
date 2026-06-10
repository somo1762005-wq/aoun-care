import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String medicineName;
  final DateTime timestamp;
  final bool takenByFather;
  final String timeLabel;

  ActivityLog({
    required this.id,
    required this.medicineName,
    required this.timestamp,
    required this.takenByFather,
    required this.timeLabel,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'timestamp': Timestamp.fromDate(timestamp),
      'takenByFather': takenByFather,
      'timeLabel': timeLabel,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime ts;
    if (map['timestamp'] is Timestamp) {
      ts = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      ts = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return ActivityLog(
      id: documentId,
      medicineName: map['medicineName'] ?? '',
      timestamp: ts,
      takenByFather: map['takenByFather'] ?? false,
      timeLabel: map['timeLabel'] ?? '',
    );
  }
}
