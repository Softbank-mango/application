// --- 데이터 모델 클래스 ---
class LogEntry {
  final DateTime time;
  final String message;
  final String status;
  LogEntry({required this.time, required this.message, required this.status});
}