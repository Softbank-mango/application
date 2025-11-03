import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart'; // 차트 임포트
import 'package:intl/intl.dart'; // 날짜 포맷 임포트

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late IO.Socket socket;
  String deployStatus = '서버 연결 중...';
  String deployStep = '';
  final player = AudioPlayer();

  // 터미널 로그/콘솔
  List<LogEntry> logs = [];
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _consoleController = TextEditingController(); // <-- 콘솔 입력용

  // 매트릭
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  @override
  void initState() {
    super.initState();
    connectToSocket();
  }

  @override
  void dispose() {
    socket.dispose();
    player.dispose();
    _logScrollController.dispose();
    _consoleController.dispose(); // <-- 컨트롤러 해제
    super.dispose();
  }

  void connectToSocket() {
    socket = IO.io('ws://localhost:4000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Socket.io: connect');
      setState(() {
        logs.add(LogEntry(time: DateTime.now(), message: 'Deploy-Pal 서버에 연결되었습니다.', status: 'SYSTEM'));
      });
    });

    socket.on('status', (data) {
      setState(() {
        deployStatus = data['message'];
        deployStep = data['status'] ?? '';
      });
      if (deployStep == 'done') {
        player.play(AssetSource('success.mp3'));
      }
    });

    socket.on('all-logs', (data) { /* (향후 확장용) */ });

    // "새 로그" 수신 (배포 로그 및 콘솔 응답)
    socket.on('new-log', (data) {
      setState(() {
        logs.add(LogEntry(
            time: DateTime.parse(data['time']),
            message: data['message'],
            status: data['status']
        ));

        // 로그 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      });
    });

    // "매트릭" 수신 (이전과 동일)
    socket.on('metrics-update', (data) {
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
    });

    socket.onDisconnect((_) => print('Socket.io: disconnect'));
  }

  // --- (1) 메인 상단: 나무 애니메이션 ---
  Widget _buildAnimation() {
    // (이전과 동일)
    String lottieFile;
    switch (deployStep) {
      case 'linting': lottieFile = 'assets/seed.json'; break;
      case 'testing': lottieFile = 'assets/sprout.json'; break;
      case 'building': case 'deploying': case 'routing':
      lottieFile = 'assets/growing.json'; break;
      case 'done': lottieFile = 'assets/done_tree.json'; break;
      case 'failed': lottieFile = 'assets/wilted.json'; break;
      default: lottieFile = 'assets/pot.json';
    }
    return Lottie.asset(lottieFile, width: 250, height: 250);
  }

  // --- (2) 메인 상단: 배포 버튼 ---
  Widget _buildDeployButton() {
    // (이전과 동일)
    bool isDeploying = deployStep.isNotEmpty && deployStep != 'waiting' && deployStep != 'done' && deployStep != 'failed';
    if (isDeploying) return Container(height: 50);

    bool isFailed = deployStep == 'failed';
    String buttonText = isFailed ? '다시 시도 (Retry)' : '배포 시작 (Deploy)';
    IconData buttonIcon = isFailed ? Icons.refresh : Icons.rocket_launch;

    return ElevatedButton.icon(
      icon: Icon(buttonIcon, color: Colors.white),
      label: Text(buttonText, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFailed ? Colors.redAccent[700] : Colors.blueAccent[700],
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        setState(() {
          logs = []; cpuData = [FlSpot(0, 5)]; memData = [FlSpot(0, 128)]; _timeCounter = 1.0;
        });
        if (isFailed) socket.emit('start-fail');
        else socket.emit('start-deploy');
      },
    );
  }

  // --- (3) 하단 탭 1: "가짜 콘솔" (Logs 탭 업그레이드) ---
  Widget _buildConsoleArea() {
    return Container(
      color: Color(0xFF1E1E1E), // 터미널 배경색
      child: Column(
        children: [
          // "실제 로그 영역" (Expanded로 남은 공간 채우기)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  Color logColor;
                  String prefix = '[${log.status}]';
                  String message = log.message;

                  // 상태에 따라 색상 및 접두사 변경
                  switch(log.status) {
                    case 'COMMAND': // 사용자가 입력한 명령어
                      logColor = Colors.white;
                      prefix = '\$'; // 프롬프트
                      message = ' ${log.message}';
                      break;
                    case 'CONSOLE': // 콘솔의 'stdout'
                      logColor = Colors.grey[300]!;
                      prefix = ''; // 응답에는 접두사 없음
                      break;
                    case 'CONSOLE_ERROR':
                      logColor = Colors.red[300]!;
                      prefix = '';
                      break;
                    case 'FAILED':
                      logColor = Colors.red[300]!;
                      prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:';
                      break;
                    case 'DONE':
                      logColor = Colors.cyan[300]!;
                      prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:';
                      break;
                    case 'SYSTEM':
                      logColor = Colors.grey[400]!;
                      prefix = '[SYSTEM]';
                      break;
                    default: // LINTING, TESTING, BUILDING...
                      logColor = Colors.green[300]!;
                      prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:';
                  }

                  return Text(
                    '$prefix $message',
                    style: TextStyle(
                      color: logColor,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  );
                },
              ),
            ),
          ),
          // "콘솔 입력 필드"
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[900], // 입력창 배경
            child: Row(
              children: [
                Text(
                  '>', // 프롬프트
                  style: TextStyle(color: Colors.green[300], fontFamily: 'monospace', fontSize: 14),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _consoleController,
                    style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'kubectl get pods (가짜 명령어 입력...)',
                      hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'monospace'),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (command) {
                      if (command.isEmpty) return;

                      // "clear" 명령어는 클라이언트에서 처리
                      if (command.toLowerCase() == 'clear') {
                        setState(() {
                          logs = []; // 로그 리스트 비우기
                        });
                      } else {
                        // 그 외 명령어는 서버로 전송
                        socket.emit('run-command', command);
                      }

                      _consoleController.clear(); // 입력창 비우기
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // --- (4) 하단 탭 2: 매트릭 차트 ---
  Widget _buildMetricsArea() {
    // (이전과 동일)
    return Container(
      color: Color(0xFF1E1E1E),
      padding: EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('실시간 리소스 (Prometheus)', style: TextStyle(color: Colors.white, fontSize: 16)),
            SizedBox(height: 10),
            Text('CPU Usage (%)', style: TextStyle(color: Colors.cyan[300])),
            SizedBox(height: 10),
            Container(height: 150, child: _buildLineChart(cpuData, Colors.cyan)),
            SizedBox(height: 20),
            Text('Memory Usage (MB)', style: TextStyle(color: Colors.green[300])),
            SizedBox(height: 10),
            Container(height: 150, child: _buildLineChart(memData, Colors.green)),
          ],
        ),
      ),
    );
  }

  // 차트 UI 헬퍼
  LineChart _buildLineChart(List<FlSpot> data, Color color) {
    // (이전과 동일)
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[850]!, strokeWidth: 0.5)),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[800]!)),
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.3)),
          ),
        ],
      ),
    );
  }

  // --- (5) 하단 탭 3: 현재 상태 ---
  Widget _buildStatusArea() {
    // (이전과 동일)
    String statusText;
    Color statusColor;
    bool isDeploying = deployStep.isNotEmpty && deployStep != 'waiting' && deployStep != 'done' && deployStep != 'failed';

    if (isDeploying) {
      statusText = 'Deploying';
      statusColor = Colors.yellow[600]!;
    } else if (deployStep == 'failed') {
      statusText = 'Failed';
      statusColor = Colors.red[400]!;
    } else {
      statusText = 'Healthy'; // done 또는 waiting
      statusColor = Colors.green[400]!;
    }

    return Container(
      color: Color(0xFF1E1E1E),
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('현재 상태 (Current Status)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.circle, color: statusColor, size: 14),
              SizedBox(width: 8),
              Text(statusText, style: TextStyle(fontSize: 16, color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Colors.grey[800]),
          SizedBox(height: 20),
          Text('실시간 리소스 사용량', style: TextStyle(fontSize: 16, color: Colors.white70)),
          SizedBox(height: 16),
          Text(
              'CPU: ${currentMetrics['cpu']!.toStringAsFixed(1)} %',
              style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.cyan[300])
          ),
          SizedBox(height: 8),
          Text(
              'MEM: ${currentMetrics['mem']!.toStringAsFixed(1)} MB',
              style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.green[300])
          ),
        ],
      ),
    );
  }

  // --- (6) 메인 UI 빌드 ---
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Deplight',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF121212),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('🌳 Deplight (Friendly PaaS)'),
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "메인 상단" (Toss 감성)
            Expanded(
              flex: 3, // 상단 60%
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _buildAnimation(),
                        SizedBox(height: 24),
                        Text(
                          deployStatus,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        _buildDeployButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // "메인 하단" (Vercel 신뢰성) - 3개 탭 뷰
            Expanded(
              flex: 2, // 하단 40%
              child: DefaultTabController(
                length: 3, // 탭 3개
                child: Column(
                  children: [
                    // 탭바
                    Container(
                      color: Color(0xFF1E1E1E),
                      child: TabBar(
                        indicatorColor: Colors.blueAccent,
                        tabs: [
                          Tab(icon: Icon(Icons.terminal), text: 'Console'), // <-- "Logs" -> "Console"
                          Tab(icon: Icon(Icons.bar_chart), text: 'Metrics'),
                          Tab(icon: Icon(Icons.monitor_heart), text: 'Status'),
                        ],
                      ),
                    ),
                    // 탭 뷰 (남은 공간 모두 차지)
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildConsoleArea(),  // <-- "Logs" 탭을 "Console" 위젯으로 교체
                          _buildMetricsArea(),
                          _buildStatusArea(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 데이터 모델 클래스 ---
class LogEntry {
  final DateTime time;
  final String message;
  final String status;
  LogEntry({required this.time, required this.message, required this.status});
}

