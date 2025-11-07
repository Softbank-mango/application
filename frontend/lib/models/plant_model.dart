// models/plant_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'logEntry_model.dart'; // deployment.dart에서 사용하므로 임포트

class Plant {
  final String id;
  final String githubUrl; // 변경되지 않는 정보
  final String ownerUid;
  final String workspaceId;

  // --- 실시간으로 변경되는 필드 (final 제거) ---
  String name; // (was 'version')
  String status;
  Timestamp lastDeployedAt;
  double cpuUsage;
  double memUsage;
  String plantType;
  List<String> reactions;

  // --- DeploymentPage에서만 사용하는 상태 (final 아님) ---
  bool isSparkling;
  String currentStatusMessage;
  List<LogEntry> logs; //
  String aiInsight; //

  Plant({
    required this.id,
    required this.githubUrl,
    required this.name,
    required this.status,
    required this.lastDeployedAt,
    required this.cpuUsage,
    required this.memUsage,
    this.plantType = 'pot',
    this.ownerUid = '',
    this.workspaceId = '',
    this.reactions = const [],

    // DeploymentPage용 필드 초기화
    this.isSparkling = false,
    this.currentStatusMessage = '',
    this.logs = const [], //
    this.aiInsight = 'AI 분석 대기 중...', //
  });

  // Firestore 등에서 데이터를 받아오는 팩토리 생성자
  factory Plant.fromMap(Map<String, dynamic> data) {
    return Plant(
      id: data['id'],
      name: data['name'] ?? data['version'] ?? 'Unnamed App',
      githubUrl: data['githubUrl'] ?? data['description'] ?? '',
      status: data['status'] ?? 'UNKNOWN',
      lastDeployedAt: data['lastDeployedAt'] ?? Timestamp.now(),
      cpuUsage: (data['cpuUsage'] ?? 0.0).toDouble(),
      memUsage: (data['memUsage'] ?? 0.0).toDouble(),
      workspaceId: data['workspaceId'] ?? '',
      ownerUid: data['ownerUid'] ?? '',
      plantType: data['plantType'] ?? 'pot',
      reactions: List<String>.from(data['reactions'] ?? []),
      currentStatusMessage: data['status'] == 'HEALTHY' ? '배포 완료됨' : '대기 중',
      logs: [], // ShelfPage에서는 로그를 로드하지 않음
    );
  }
}