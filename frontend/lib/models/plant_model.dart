import 'logEntry_model.dart';

// --- 데이터 모델 ---
class Plant {
  final int id;
  String plant; // Lottie (pot, rose, cactus, bonsai...)
  String version; // 프로젝트 이름 (예: Unicef_dev)
  String description;
  String status; // DEPLOYING, HEALTHY, FAILED, WAITING
  String owner;
  List<String> reactions;

  List<LogEntry> logs = [];
  String aiInsight = 'AI 분석 대기 중...';
  String currentStatusMessage = '대기 중...';

  bool isSparkling = false; // (신규) Slack 반응용

  Plant({
    required this.id,
    required this.plant,
    required this.version,
    required this.description,
    required this.status,
    required this.owner,
    required this.reactions,
  });
}