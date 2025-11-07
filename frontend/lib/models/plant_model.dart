import 'package:cloud_firestore/cloud_firestore.dart';
import 'logEntry_model.dart';

class Plant {
  final String id;
  final String ownerUid;
  final String workspaceId;
  final String description;

  String plantType;
  String version;
  String status;
  List<String> reactions;

  List<LogEntry> logs = [];
  String aiInsight = 'AI 분석 대기 중...';
  String currentStatusMessage = '대기 중';
  bool isSparkling = false;

  Plant({
    required this.id,
    required this.plantType,
    required this.version,
    required this.description,
    required this.status,
    required this.ownerUid,
    required this.workspaceId,
    required this.reactions,
  });

  // (★★★★★ 신규 ★★★★★: Socket.io가 보낸 Map용)
  factory Plant.fromMap(Map<String, dynamic> data) {
    return Plant(
      id: data['id'],
      plantType: data['plantType'] ?? 'pot',
      version: data['version'] ?? 'N/A',
      description: data['description'] ?? 'No description',
      status: data['status'] ?? 'UNKNOWN',
      ownerUid: data['ownerUid'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      reactions: List<String>.from(data['reactions'] ?? []),
    );
  }
}