// pages/deployment.dart

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../models/logEntry_model.dart';
import '../models/user_data.dart';

class DeploymentPage extends StatefulWidget {
  final Plant plant;
  final IO.Socket socket;
  final User currentUser;
  final UserData? userData;
  final String workspaceId;

  // (★★★★★) app_core의 body 교체를 위한 콜백
  final VoidCallback onGoBackToDashboard;
  final VoidCallback onShowSettings; // (우측 "설정" 버튼용)

  const DeploymentPage({
    Key? key,
    required this.plant,
    required this.socket,
    required this.currentUser,
    this.userData,
    required this.workspaceId,
    required this.onGoBackToDashboard,
    required this.onShowSettings,
  }) : super(key: key);

  @override
  _DeploymentPageState createState() => _DeploymentPageState();
}

class _DeploymentPageState extends State<DeploymentPage> {
  late Plant plant;

  // (Stateful) 실시간 데이터
  List<LogEntry> logs = [];
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  final ScrollController _logScrollController = ScrollController();

  // --- 이미지 기준 색상 정의 ---
  static const Color _backgroundColor = Color(0xFFF9FAFB);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF111827);
  static const Color _subTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _primaryColor = Color(0xFF678AFB);
  static const Color _successColor = Color(0xFF00B894); // (정상)
  static const Color _successBgColor = Color(0xFFF0FDF4); // (정상 배경)
  static const Color _memColor = Color(0xFF34D399); // (메모리 바)

  @override
  void initState() {
    super.initState();
    plant = widget.plant;
    // (이 페이지가 로드될 때 로그/메트릭을 새로 요청해야 할 수 있음)
    // widget.socket.emit('get-logs-for-plant', plant.id);

    widget.socket.on('status-update', _onStatusUpdate);
    widget.socket.on('new-log', _onNewLog);
    widget.socket.on('metrics-update', _onMetricsUpdate);

    // (임시 데이터 - 차트 모양 확인용)
    cpuData = _getDummyChartData(40, 75);
    memData = _getDummyChartData(30, 55);
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    widget.socket.off('status-update', _onStatusUpdate);
    widget.socket.off('new-log', _onNewLog);
    widget.socket.off('metrics-update', _onMetricsUpdate);
    super.dispose();
  }

  // --- 소켓 리스너 (기존 deployment.dart와 유사) ---
  void _onStatusUpdate(dynamic data) {
    if (!mounted || data['id'] != plant.id) return;
    setState(() {
      plant.status = data['status'];
      plant.currentStatusMessage = data['message'];
    });
  }

  void _onNewLog(dynamic data) {
    if (!mounted || data['id'] != plant.id) return;
    final log = LogEntry(
        time: DateTime.parse(data['log']['time']),
        message: data['log']['message'],
        status: data['log']['status']);
    setState(() {
      logs.add(log);
      if (logs.length > 100) logs.removeAt(0);
      if (log.status == 'AI_INSIGHT') plant.aiInsight = log.message;
    });
    _scrollToBottom(_logScrollController);
  }

  void _onMetricsUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      double cpu = data['cpu'].toDouble();
      double mem = data['mem'].toDouble();
      currentMetrics = {'cpu': cpu, 'mem': mem};
      cpuData.add(FlSpot(_timeCounter, cpu));
      memData.add(FlSpot(_timeCounter, mem));
      if (cpuData.length > 20) cpuData.removeAt(0);
      if (memData.length > 20) memData.removeAt(0);
      _timeCounter += 1.0;
    });
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(controller.position.maxScrollExtent,
            duration: Duration(milliseconds: 100), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
        child: Column(
          children: [
            // 1. 페이지 헤더 (뒤로가기 버튼)
            _buildHeader(context),
            const SizedBox(height: 24),

            // 상단 Row (앱 정보 + 배포 정보)
            // IntrinsicHeight를 사용해 두 카드의 높이를 동일하게 맞춤
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1-1. 왼쪽 앱 정보 카드 (70%)
                  Expanded(
                    flex: 7,
                    child: _buildAppInfoCardWithUsage(context),
                  ),
                  const SizedBox(width: 24),

                  // 2. _buildSidebar 대신 _buildDeploymentInfoCard 직접 호출
                  Expanded(
                    flex: 3,
                    child: _buildDeploymentInfoCard(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 하단 Row (메트릭 + 로그)
            // IntrinsicHeight를 사용해 두 카드의 높이를 동일하게 맞춤
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // (자식들이 높이를 꽉 채우게 함)
                children: [
                  // 2-1. 실시간 메트릭
                  Expanded(
                    flex: 7,
                    child: _buildMetricsChart(), // (차트가 꽉 차도록 수정됨)
                  ),
                  const SizedBox(width: 24),
                  // 2-2. 실시간 로그
                  Expanded(
                    flex: 3,
                    child: _buildLogs(), // (이 카드의 높이를 기준으로 함)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. AI 인사이트 (Full Width)
            _buildAiInsight(),
          ],
        ),
      ),
    );
  }

  // --- 1. 페이지 헤더 (뒤로가기) ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onGoBackToDashboard, // (app_core 콜백)
          icon: const Icon(Icons.arrow_back, size: 16, color: _primaryColor),
          label: const Text("대시보드로 돌아가기"),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoCardWithUsage(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 앱 정보 (Row)
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.desktop_windows, color: _primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(plant.githubUrl, style: TextStyle(color: _subTextColor)),
                  const SizedBox(height: 4),
                  Text("https://frontend-app.deplight.com", // (임시 하드코딩)
                      style: TextStyle(color: _primaryColor, fontSize: 13)),
                ],
              ),
              const Spacer(),
              // 상태 칩
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _successBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: _successColor),
                    SizedBox(width: 4),
                    Text("정상",
                        style: TextStyle(
                            color: _successColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 리프레시 버튼
              IconButton(
                icon: Icon(Icons.refresh, color: _subTextColor),
                onPressed: () { /* TODO: 데이터 리프레시 */ },
              ),
            ],
          ),
          const SizedBox(height: 24), // (섹션 구분)

          // (★★★★★ 2. CPU/Mem 바 (Row)가 카드 안으로 이동 ★★★★★)
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  "CPU 사용량",
                  plant.cpuUsage, // (0.0 ~ 1.0)
                  _primaryColor,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildProgressBar(
                  "메모리 사용량",
                  plant.memUsage, // (0.0 ~ 1.0)
                  _memColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- (★★★★★ 3. _buildSidebar에서 로그 카드 제거 ★★★★★) ---
  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        // 배포 정보
        _buildDeploymentInfoCard(context),
        const SizedBox(height: 16),
        // 재배포 버튼
        ElevatedButton(
          onPressed: () { /* TODO: 재배포 로직 */ },
          child: Text("재배포"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        // 설정 버튼
        OutlinedButton(
          onPressed: widget.onShowSettings, // (app_core 콜백)
          child: Text("설정", style: TextStyle(color: _textColor)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 44),
            side: BorderSide(color: _borderColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        // (로그 카드가 여기에서 제거됨)
      ],
    );
  }

  // (공통) 카드 스타일
  Widget _buildBaseCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      // height: double.infinity,
      padding: padding ?? const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  // (공통) 카드 헤더
  Widget _buildCardHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: _textColor, fontSize: 16),
        ),
        if (action != null) action,
      ],
    );
  }

  // (본문 1) 앱 정보
  Widget _buildAppInfoCard() {
    return _buildBaseCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.desktop_windows, color: _primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plant.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(plant.githubUrl, style: TextStyle(color: _subTextColor)),
              const SizedBox(height: 4),
              Text("https://frontend-app.deplight.com", // (임시 하드코딩)
                  style: TextStyle(color: _primaryColor, fontSize: 13)),
            ],
          ),
          const Spacer(),
          // 상태 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _successBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: _successColor),
                SizedBox(width: 4),
                Text("정상",
                    style: TextStyle(
                        color: _successColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 리프레시 버튼
          IconButton(
            icon: Icon(Icons.refresh, color: _subTextColor),
            onPressed: () { /* TODO: 데이터 리프레시 */ },
          ),
        ],
      ),
    );
  }

  // (본문 2) CPU/메모리 사용량
  Widget _buildUsageBars() {
    return Row(
      children: [
        Expanded(
          child: _buildBaseCard(
            padding: EdgeInsets.all(20),
            child: _buildProgressBar(
              "CPU 사용량",
              plant.cpuUsage, // (0.0 ~ 1.0)
              _primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildBaseCard(
            padding: EdgeInsets.all(20),
            child: _buildProgressBar(
              "메모리 사용량",
              plant.memUsage, // (0.0 ~ 1.0)
              _memColor,
            ),
          ),
        ),
      ],
    );
  }

  // (Helper) 프로그레스 바
  Widget _buildProgressBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
            Text(
              "${(percent * 100).toInt()}%",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearPercentIndicator(
          percent: percent,
          lineHeight: 10,
          backgroundColor: color.withOpacity(0.1),
          progressColor: color,
          barRadius: Radius.circular(5),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // (본문 3) 실시간 메트릭
  Widget _buildMetricsChart() {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildCardHeader("실시간 메트릭"),
          const SizedBox(height: 32),
          // (★★★★★) 고정 높이 제거, Expanded로 변경
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: false),
                clipData: FlClipData.all(),

                // (이하 차트 설정은 이전과 동일)
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: _borderColor, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 20, // 0, 20, 40, 60, 80
                      getTitlesWidget: (value, meta) {
                        if (value % 20 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: _subTextColor, fontSize: 12),
                            textAlign: TextAlign.right,
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4, // 4시간 단위
                      getTitlesWidget: (value, meta) {
                        String text;
                        switch (value.toInt()) {
                          case 0: text = '00:00'; break;
                          case 4: text = '04:00'; break;
                          case 8: text = '08:00'; break;
                          case 12: text = '12:00'; break;
                          case 16: text = '16:00'; break;
                          case 20: text = '20:00'; break;
                          case 24: text = '24:00'; break;
                          default: return Container();
                        }
                        return Text(
                          text,
                          style: TextStyle(color: _subTextColor, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                minX: 0,
                maxX: 24,
                minY: 0,
                maxY: 80, // (이미지와 동일하게 80)
                lineBarsData: [
                  _buildLineChartData(cpuData, _primaryColor),
                  _buildLineChartData(memData, _memColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (Helper) 라인 차트 데이터
  LineChartBarData _buildLineChartData(List<FlSpot> data, Color color) {
    return LineChartBarData(
      spots: data,
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  // (본문 4) 실시간 로그
  Widget _buildLogs() {
    // (★★★★★) 예시 로그 데이터를 여기로 이동
    final logMessages = [
      "[2024-01-01 10:00:01] 팜 시작됨",
      "[2024-01-01 10:00:02] 데이터베이스 연결 성공",
      "[2024-01-01 10:00:10] 404 포트 3000에서 대기중",
      "[2024-01-01 10:00:15] GET /api/users - 200 OK",
      "[2024-01-01 10:00:32] POST /api/auth/login - 200 OK",
      "[2024-01-01 10:01:05] GET /api/dashboard - 200 OK",
      "[2024-01-01 10:01:23] WebSocket 연결 설정됨",
      "[2024-01-01 10:02:01] 메모리 사용량: 62%",
      "[2024-01-01 10:02:15] CPU 사용량: 45%",
    ];

    return _buildBaseCard(
      child: Column(
        children: [
          _buildCardHeader("실시간 로그", action: Icon(Icons.download_outlined, color: _subTextColor)),
          const SizedBox(height: 16),
          // (★★★★★) 이 Container의 높이가 메트릭 차트의 높이를 결정함
          Container(
            height: 310,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _textColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _logScrollController,
              // (★★★★★) itemCount 및 itemBuilder 수정
              itemCount: logMessages.length,
              itemBuilder: (context, index) {
                final logText = logMessages[index];

                // (실제 데이터 사용 시)
                // final log = logs[index];
                // final logText = '[${DateFormat('HH:mm:ss').format(log.time.toLocal())}] ${log.message}';

                return Text(
                  logText,
                  style: TextStyle(
                    color: _successColor,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // (본문 5) AI 인사이트
  Widget _buildAiInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFFF5F3FF), // (연한 보라색 배경)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEDE9FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI 인사이트",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5B21B6),
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  plant.aiInsight,
                  style: TextStyle(color: Color(0xFF6D28D9), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // (사이드바 1) 배포 정보
  Widget _buildDeploymentInfoCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("배포 정보"),
          const SizedBox(height: 16),
          _buildInfoRow("마지막 배포", "2시간 전"),
          _buildInfoRow("배포 환경", "Production"),
          _buildInfoRow("인스턴스", "2개"),
          _buildInfoRow("리전", "Asia-Northeast1"),

          // (★★★★★) Spacer가 버튼들을 하단으로 밀어냄
          const Spacer(),

          // (★★★★★) 버튼들이 카드로 이동
          ElevatedButton(
            onPressed: () { /* TODO: 재배포 로직 */ },
            child: Text("재배포"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onShowSettings, // (app_core 콜백)
            child: Text("설정", style: TextStyle(color: _textColor)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(color: _borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // (Helper) 정보 행 (Key-Value)
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: _subTextColor)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: _textColor)),
        ],
      ),
    );
  }

  // (임시) 차트 더미 데이터
  List<FlSpot> _getDummyChartData(double min, double max) {
    return [
      FlSpot(0, (min + max) / 2),
      FlSpot(4, min),
      FlSpot(8, min + 5),
      FlSpot(12, max),
      FlSpot(16, max - 10),
      FlSpot(20, min + 15),
      FlSpot(24, max - 20),
    ];
  }
}