import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../models/logEntry_model.dart';
import '../models/user_data.dart';
import '../widgets/rollback_dialog.dart';


class DeploymentPage extends StatefulWidget {
  final Plant plant;
  final IO.Socket socket;
  final User currentUser;
  final UserData? userData;
  final String workspaceId;

  final VoidCallback onGoBackToDashboard;
  final VoidCallback onShowSettings;

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

  List<LogEntry> logs = [];
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  final ScrollController _logScrollController = ScrollController();

  // --- 색상 정의 ---
  static const Color _backgroundColor = Color(0xFFF9FAFB);
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF111827);
  static const Color _subTextColor = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _primaryColor = Color(0xFF678AFB);
  static const Color _successColor = Color(0xFF00B894);
  static const Color _successBgColor = Color(0xFFF0FDF4);
  static const Color _memColor = Color(0xFF34D399);

  // 1. 더미 데이터 생성 (이 부분은 실제 데이터로 대체해야 함)
  final List<DeploymentHistoryItem> _dummyHistory = [
    DeploymentHistoryItem(
      id: "3",
      version: "v1.2.3",
      statusText: "현재",
      statusColor: const Color(0xFF42A5F5), // 파란색
      deployedAt: DateTime(2024, 1, 1, 14, 30),
      deployer: "김개발",
      commitSha: "a1b2c3d",
      commitMessage: "feat: 새로운 대시보드 UI 추가",
      isCurrentVersion: true,
    ),
    DeploymentHistoryItem(
      id: "2",
      version: "v1.2.2",
      statusText: "성공",
      statusColor: const Color(0xFF66BB6A), // 초록색
      deployedAt: DateTime(2024, 1, 1, 10, 15),
      deployer: "이개발",
      commitSha: "e4f5g6h",
      commitMessage: "fix: 로그인 버그 수정",
    ),
    DeploymentHistoryItem(
      id: "1",
      version: "v1.2.1",
      statusText: "실패",
      statusColor: const Color(0xFFEF5350), // 빨간색
      deployedAt: DateTime(2024, 1, 1, 9, 0),
      deployer: "박개발",
      commitSha: "i7j8k9l",
      commitMessage: "feat: 초기 배포",
    ),
  ];

  @override
  void initState() {
    super.initState();
    plant = widget.plant;

    widget.socket.on('status-update', _onStatusUpdate);
    widget.socket.on('new-log', _onNewLog);
    _toggleMetricsListeners(true);

    widget.socket.emit('get-logs-for-plant', plant.id);

    cpuData = _getDummyChartData(40, 75);
    memData = _getDummyChartData(30, 55);
  }

  @override
  void dispose() {
    _logScrollController.dispose();
    widget.socket.off('status-update', _onStatusUpdate);
    widget.socket.off('new-log', _onNewLog);
    _toggleMetricsListeners(false);
    super.dispose();
  }

  void _toggleMetricsListeners(bool enable) {
    if (enable) {
      widget.socket.on('metrics-update', _onMetricsUpdate);
      print("Metrics listener enabled.");
    } else {
      widget.socket.off('metrics-update', _onMetricsUpdate);
      print("Metrics listener temporarily disabled.");
    }
  }

// 2. "롤백" 버튼 클릭 시 이 함수 호출
  void _showRollbackModal(BuildContext context) {
    // 현재 프레임에서 setState 충돌을 막기 위해 잠시 리스너를 끕니다.
    _toggleMetricsListeners(false);

    // 2단계: 다음 프레임에서 모달 띄우기 (마우스 트래커 충돌 회피)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // showDialog는 Future를 반환하며, 모달이 닫힐 때 Future가 완료됩니다.
      showDialog(
        context: context,
        barrierDismissible: true, // Esc 키 등으로 닫기 허용
        builder: (BuildContext dialogContext) {
          return RollbackDialog(
            currentAppName: widget.plant.name,
            history: _dummyHistory,
            onRollbackConfirmed: (selectedItem) {
              // 모달에서 '롤백 실행' 버튼이 눌렸을 때 실행됩니다.

              // 1. 서버에 요청
              widget.socket.emit('start-rollback', {
                'plantId': widget.plant.id,
                // ... (추가 데이터)
              });

              // 2. 알림 표시 (onRollbackConfirmed 내부에서는 context가 안전합니다)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${selectedItem.version}으로 롤백 시작...")),
              );

              // Note: 모달은 이 콜백 실행 후 자동으로 닫힙니다.
            },
          );
        },
      ).then((_) {
        // 모달이 '취소', '롤백 실행', 혹은 외부 탭 등으로 닫히면 실행됩니다.
        _toggleMetricsListeners(true);
      });
    });
  }

  // --- 소켓 리스너 ---
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
      plant.cpuUsage = cpu / 100.0;
      plant.memUsage = mem / 100.0;

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
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - 96.0;
          final columnSpacing = 24.0;
          final leftWidth = (contentWidth * 0.7) - (columnSpacing / 2);
          final rightWidth = (contentWidth * 0.3) - (columnSpacing / 2);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: leftWidth, child: _buildAppInfoCardWithUsage(context)),
                    SizedBox(width: columnSpacing),
                    SizedBox(width: rightWidth, child: _buildDeploymentInfoCard(context)),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: leftWidth, child: _buildMetricsChart()),
                    SizedBox(width: columnSpacing),
                    SizedBox(width: rightWidth, child: _buildLogs()),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAiInsight(),
              ],
            ),
          );
        },
      ),
    );
  }



  // --- 1. 페이지 헤더 (뒤로가기) ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.onGoBackToDashboard,
          icon: const Icon(Icons.arrow_back, size: 16, color: _primaryColor),
          label: const Text("대시보드로 돌아가기"),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),
      ],
    );
  }

  // (공통) 카드 스타일
  Widget _buildBaseCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
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
          percent: percent.clamp(0.0, 1.0),
          lineHeight: 10,
          backgroundColor: color.withOpacity(0.1),
          progressColor: color,
          barRadius: Radius.circular(5),
          padding: EdgeInsets.zero,
        ),
      ],
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

  // (2-1) 앱 정보 + 사용량 카드
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
                  Text("https://frontend-app.deplight.com",
                      style: TextStyle(color: _primaryColor, fontSize: 13)),
                ],
              ),
              // const Spacer(),
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
          const SizedBox(height: 24),

          // 2. CPU/Mem 바 (Row)
          Row(
            children: [
              // (★★★★★ 5. Expanded 대신 Flexible 사용 ★★★★★)
              Flexible(
                fit: FlexFit.tight,
                child: _buildProgressBar(
                  "CPU 사용량",
                  plant.cpuUsage,
                  _primaryColor,
                ),
              ),
              const SizedBox(width: 24),
              Flexible(
                fit: FlexFit.tight,
                child: _buildProgressBar(
                  "메모리 사용량",
                  plant.memUsage,
                  _memColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (2-2) 배포 정보 카드 (버튼 포함)
  Widget _buildDeploymentInfoCard(BuildContext context) {
    // --- (신규) 버튼 스타일 정의 ---

    // "재배포" 버튼 스타일 (파란색 배경)
    final ButtonStyle redeployButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2962FF), // (이미지 기준 파란색)
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48), // (높이)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0, // 그림자 없음
    );

    // "롤백", "설정" 버튼 스타일 (흰색 배경, 회색 테두리)
    final ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF424242), // (어두운 텍스트 색상)
      minimumSize: const Size(double.infinity, 48), // (높이)
      side: BorderSide(color: const Color(0xFFE0E0E0), width: 1.5), // (회색 테두리)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );

    // --- (수정) 기존 Card 위젯 ---
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader("배포 정보"),
          const SizedBox(height: 16),
          _buildInfoRow("마지막 배포", DateFormat('yy-MM-dd HH:mm').format(plant.lastDeployedAt.toDate())),
          _buildInfoRow("배포 환경", plant.plantType == 'pot' ? "Development" : "Production"), // 예시
          _buildInfoRow("인스턴스", "2개"),
          _buildInfoRow("리전", "Asia-Northeast1"),
          // (수정) 정보와 버튼 사이 간격 추가
          const SizedBox(height: 24),

          // (수정) 기존 버튼들을 삭제하고 3개 버튼 Column으로 교체
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 재배포 버튼
              ElevatedButton(
                onPressed: () {
                  /* TODO: 재배포 로직 */
                },
                style: redeployButtonStyle,
                child: const Text("재배포", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              const SizedBox(height: 12), // (버튼 사이 간격)

              // 2. (신규) 롤백 버튼
              OutlinedButton.icon(
                onPressed: () => _showRollbackModal(context),
                style: outlinedButtonStyle,
                icon: const Icon(Icons.history, size: 20),
                label: const Text("롤백", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),

              const SizedBox(height: 12), // (버튼 사이 간격)

              // 3. 설정 버튼 (기존 버튼 수정)
              OutlinedButton(
                onPressed: widget.onShowSettings, // (app_core 콜백)
                style: outlinedButtonStyle,
                child: const Text("설정", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (3-1) 실시간 메트릭 카드
  Widget _buildMetricsChart() {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildCardHeader("실시간 메트릭"),
          const SizedBox(height: 32),
          Container(
            height: 310, // (로그 카드와 높이 맞춤)
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: false),
                clipData: FlClipData.all(),
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
                      interval: 20,
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
                      interval: 4,
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
                maxY: 80,
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

  // (3-2) 실시간 로그 카드
  Widget _buildLogs() {
    return _buildBaseCard(
      child: Column(
        children: [
          _buildCardHeader("실시간 로그", action: Icon(Icons.download_outlined, color: _subTextColor)),
          const SizedBox(height: 16),
          Container(
            height: 310, // (메트릭 차트와 높이 맞춤)
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _textColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final logEntry = logs[index];

                Color logColor = _successColor;
                if (logEntry.status == 'TRAFFIC_HIT') logColor = Colors.lightBlueAccent;
                if (logEntry.status.contains('ERROR')) logColor = Colors.redAccent;

                final time = DateFormat('HH:mm:ss').format(logEntry.time);

                return Text(
                  "[$time] ${logEntry.message}",
                  style: TextStyle(
                    color: logColor,
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

  // (4) AI 인사이트 카드
  Widget _buildAiInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFEDE9FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: Color(0xFF8B5CF6)),
          const SizedBox(width: 16),
          Flexible( // (텍스트가 길어질 경우를 대비해 Flexible 사용)
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
}