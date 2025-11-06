import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_model.dart';
import '../models/logEntry_model.dart';
import '../widgets/profile_menu.dart';
import '../l10n/app_localizations.dart';

// --- (6) "배포 상세" 페이지 (작업대) ---
class DeploymentPage extends StatefulWidget {
  final Plant plant;
  final IO.Socket socket;
  final Map<String, double> initialMetrics;
  final List<FlSpot> initialCpuData;
  final List<FlSpot> initialMemData;
  final List<LogEntry> globalLogs;
  final User currentUser;
  final Map<String, dynamic>? userData;
  final String workspaceId;

  const DeploymentPage(
      {Key? key,
        required this.plant,
        required this.socket,
        required this.initialMetrics,
        required this.initialCpuData,
        required this.initialMemData,
        required this.globalLogs,
        required this.currentUser,
        this.userData,
        required this.workspaceId,
      })
      : super(key: key);

  @override
  _DeploymentPageState createState() => _DeploymentPageState();
}

class _DeploymentPageState extends State<DeploymentPage>
    with TickerProviderStateMixin {
  late Plant plant;
  Map<String, double> currentMetrics = {};
  List<FlSpot> cpuData = [];
  List<FlSpot> memData = [];
  double _timeCounter = 1.0;

  late TabController _tabController;
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _consoleController = TextEditingController();
  final ScrollController _trafficScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    plant = widget.plant;
    currentMetrics = widget.initialMetrics;
    cpuData = List.from(widget.initialCpuData);
    memData = List.from(widget.initialMemData);
    _timeCounter = (cpuData.lastOrNull?.x ?? 0.0) + 1.0;

    _tabController = TabController(length: 5, vsync: this);

    widget.socket.on('status-update', _onStatusUpdate);
    widget.socket.on('new-log', _onNewLog);
    widget.socket.on('plant-complete', _onPlantComplete);
    widget.socket.on('metrics-update', _onMetricsUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    _consoleController.dispose();
    _trafficScrollController.dispose();
    widget.socket.off('status-update', _onStatusUpdate);
    widget.socket.off('new-log', _onNewLog);
    widget.socket.off('plant-complete', _onPlantComplete);
    widget.socket.off('metrics-update', _onMetricsUpdate);
    super.dispose();
  }

  void _onStatusUpdate(dynamic data) {
    if (!mounted || data['id'] != plant.id) return;
    setState(() {
      plant.status = data['status'];
      plant.currentStatusMessage = data['message'];
    });
  }

  void _onNewLog(dynamic data) {
    if (!mounted) return;
    final log = LogEntry(
        time: DateTime.parse(data['log']['time']),
        message: data['log']['message'],
        status: data['log']['status']);
    if (data['id'] == plant.id) {
      setState(() {
        plant.logs.add(log);
        if (log.status == 'AI_INSIGHT') plant.aiInsight = log.message;
      });
      _scrollToBottom(_logScrollController);
    }
  }

  void _onPlantComplete(dynamic data) {
    if (!mounted || data['id'] != plant.id) return;
    setState(() {
      plant.status = data['status'];
      plant.plantType = data['plant'];
      plant.version = data['version'];
    });
  }

  void _onMetricsUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      double cpu = data['cpu'].toDouble(); double mem = data['mem'].toDouble();
      currentMetrics = {'cpu': cpu, 'mem': mem};
      cpuData.add(FlSpot(_timeCounter, cpu)); memData.add(FlSpot(_timeCounter, mem));
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

  // (신규) "깨우기" 버튼 로직
  void _wakeUpApp() {
    setState(() {
      plant.logs = [];
      plant.aiInsight = 'AI 분석 대기 중...';
      cpuData = [FlSpot(0, 5)]; memData = [FlSpot(0, 128)]; _timeCounter = 1.0;
    });
    // 'start-deploy'를 호출하되, "깨우기" 플래그를 전송
    widget.socket.emit('start-deploy', {
      'id': plant.id, // (신규) 겨울잠은 "id"가 필요
      'version': plant.version,
      'description': 'Waking up from hibernation...',
      'isWakeUp': true, // (신규)
      'workspaceId': widget.workspaceId
    });
  }

  // --- (1) 메인 상단: 나무 애니메이션 ---
  Widget _buildAnimation() {
    String lottieFile;
    switch (plant.status) {
      case 'linting': case 'ROLLBACK': lottieFile = 'assets/seed.json'; break;
      case 'testing': lottieFile = 'assets/sprout.json'; break;
      case 'building': case 'deploying': case 'routing': case 'CLEANUP':
      lottieFile = 'assets/growing.json'; break;
      case 'done': case 'HEALTHY': lottieFile = 'assets/done_tree.json'; break;
      case 'failed': case 'FAILED': lottieFile = 'assets/wilted_fly.json'; break;
      case 'SLEEPING': lottieFile = 'assets/pot_sleeping.json'; break; // (신규)
      default: lottieFile = 'assets/pot.json';
    }
    return Lottie.asset(lottieFile, width: 250, height: 250);
  }

  // --- (이하 모든 _build... 탭 위젯은 이전 버전과 100% 동일 ---
  // ... (_buildConsoleArea, _buildMetricsArea, _buildStatusArea, _buildGlobalTrafficArea, _buildEnvArea)
  // ... (LineChart 헬퍼)

  // (이전 코드와 동일 - _buildConsoleArea)
  Widget _buildConsoleArea() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container( color: theme.colorScheme.surface, child: Column( children: [
      Expanded( child: Padding( padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: ListView.builder(
          controller: _logScrollController,
          itemCount: plant.logs.length,
          itemBuilder: (context, index) {
            final log = plant.logs[index];
            Color logColor; String prefix = '[${log.status}]'; String message = log.message;
            switch(log.status) {
              case 'COMMAND': logColor = theme.textTheme.bodyMedium!.color!; prefix = '\$'; message = ' ${log.message}'; break;
              case 'CONSOLE': logColor = theme.textTheme.bodyMedium!.color!.withOpacity(0.8); prefix = ''; break;
              case 'CONSOLE_ERROR': logColor = Colors.red[700]!; prefix = ''; break;
              case 'FAILED': logColor = Colors.red[700]!; prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:'; break;
              case 'DONE': logColor = Colors.blue[800]!; prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:'; break;
              case 'SYSTEM': logColor = theme.hintColor; prefix = '[SYSTEM]'; break;
              case 'TRAFFIC_HIT': logColor = Colors.lightBlue[300]!; prefix = '[TRAFFIC]'; break;
              case 'AI_INSIGHT': logColor = Colors.purple[700]!; prefix = '[AI]'; break;
              case 'ROLLBACK': logColor = Colors.orange[800]!; prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:'; break;
              default: logColor = Colors.green[800]!; prefix = '[${log.status}] ${DateFormat('HH:mm:ss').format(log.time.toLocal())}:';
            }
            return Text('$prefix $message', style: TextStyle(color: logColor, fontFamily: 'monospace', fontSize: 13));
          },
        ),
      )),
      Container(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: theme.scaffoldBackgroundColor,
          child: Row( children: [
            Text('>', style: TextStyle(color: Colors.green[800], fontFamily: 'monospace', fontSize: 14)), SizedBox(width: 8),
            Expanded( child: TextField(
              controller: _consoleController, style: TextStyle(color: theme.textTheme.bodyMedium!.color, fontFamily: 'monospace', fontSize: 14),
              decoration: InputDecoration(
                  hintText: l10n.consoleHint,
                  hintStyle: TextStyle(color: theme.hintColor, fontFamily: 'monospace'),
                  border: InputBorder.none, isDense: true
              ),
              onSubmitted: (command) {
                if (command.isEmpty) return;
                if (command.toLowerCase() == 'clear') { setState(() => plant.logs = []); }
                else widget.socket.emit('run-command', command);
                _consoleController.clear();
              },
            )),
          ])),
    ]));
  }

  // (이전 코드와 동일 - _buildMetricsArea)
  Widget _buildMetricsArea() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView( child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.vitalsTitle, style: theme.textTheme.titleLarge),
            SizedBox(height: 20),
            Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.vitalsCPU, style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Container(height: 150, child: _buildLineChart(cpuData, Colors.blue)),
                    ],
                  ),
                )
            ),
            SizedBox(height: 16),
            Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.vitalsMemory, style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Container(height: 150, child: _buildLineChart(memData, Colors.green)),
                    ],
                  ),
                )
            ),
          ],
        )));
  }
  LineChart _buildLineChart(List<FlSpot> data, Color color) {
    final theme = Theme.of(context);
    return LineChart( LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: true, getDrawingHorizontalLine: (v) => FlLine(color: theme.dividerColor, strokeWidth: 0.5)),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [ LineChartBarData(
        spots: data, isCurved: true, color: color, barWidth: 3,
        dotData: FlDotData(show: false), belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
      )],
    ));
  }

  // (이전 코드와 동일 - _buildStatusArea)
  Widget _buildStatusArea() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    String statusText; Color statusColor;
    bool isDeploying = plant.status.isNotEmpty && plant.status != 'waiting' && plant.status != 'done' && plant.status != 'FAILED' && plant.status != 'HEALTHY';
    bool isHealthy = plant.status == 'HEALTHY' || plant.status == 'done';

    if (isDeploying) { statusText = 'Growing'; statusColor = Colors.orange[700]!; }
    else if (plant.status == 'FAILED') { statusText = 'Wilted'; statusColor = Colors.red[700]!; }
    else { statusText = 'Healthy'; statusColor = Colors.green[700]!; }

    return Container(
        color: theme.scaffoldBackgroundColor,
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${l10n.statusTitle} (${plant.version})", style: theme.textTheme.titleLarge),
                    SizedBox(height: 20), Row( children: [
                      Icon(Icons.circle, color: statusColor, size: 14), SizedBox(width: 8),
                      Text(statusText, style: TextStyle(fontSize: 16, color: statusColor, fontWeight: FontWeight.bold)),
                    ]),
                    if (isHealthy && !isDeploying)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextButton.icon(
                          icon: Icon(Icons.history, color: Colors.red[700]),
                          label: Text(l10n.rollbackNow, style: TextStyle(color: Colors.red[700])),
                          style: TextButton.styleFrom( side: BorderSide(color: Colors.red[200]!) ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(l10n.rollbackConfirmTitle),
                                content: Text(l10n.rollbackConfirmMessage),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      widget.socket.emit('start-rollback', { 'id': plant.id });
                                      _tabController.animateTo(0);
                                    },
                                    child: Text(l10n.rollbackAction, style: TextStyle(color: Colors.red[700])),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 20), Divider(color: theme.dividerColor),
                    SizedBox(height: 20), Text(l10n.statusResources, style: theme.textTheme.titleMedium),
                    SizedBox(height: 16),
                    Text('CPU: ${currentMetrics['cpu']!.toStringAsFixed(1)} %', style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.blue[700])),
                    SizedBox(height: 8),
                    Text('MEM: ${currentMetrics['mem']!.toStringAsFixed(1)} MB', style: TextStyle(fontFamily: 'monospace', fontSize: 14, color: Colors.green[700])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(l10n.statusAITitle, style: theme.textTheme.titleLarge?.copyWith(color: Colors.purple[700])),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16), width: double.infinity,
              decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple[200]!)),
              child: Text(plant.aiInsight, style: TextStyle(fontSize: 14, color: Colors.purple[900], height: 1.5)),
            ),
          ],
        )));
  }

  // (이전 코드와 동일 - _buildGlobalTrafficArea)
  Widget _buildGlobalTrafficArea() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final trafficLogs = widget.globalLogs.where((log) => log.status == 'TRAFFIC_HIT').toList();

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1))
            ),
            padding: EdgeInsets.all(16),
            child: Row(children: [
              Icon(Icons.public, color: theme.colorScheme.primary, size: 30),
              SizedBox(width: 16),
              Text(l10n.trafficTitle, style: theme.textTheme.titleLarge),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              controller: _trafficScrollController,
              padding: EdgeInsets.all(16),
              itemCount: trafficLogs.length,
              itemBuilder: (context, index) {
                final log = trafficLogs[trafficLogs.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '[${DateFormat('HH:mm:ss').format(log.time.toLocal())}] ${log.message}',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontFamily: 'monospace', fontSize: 13),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // (이전 코드와 동일 - _buildEnvArea)
  Widget _buildEnvArea() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final envVars = {
      'API_KEY': '********** (숨김)', 'DB_HOST': 'prod.rds.aws.com', 'DB_USER': 'postgres',
      'DB_PASS': '********** (숨김)', 'ENABLE_FEATURE_X': 'true',
    };

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.envTitle, style: theme.textTheme.titleLarge),
          SizedBox(height: 10),
          Text(l10n.envSubtitle, style: theme.textTheme.bodySmall),
          SizedBox(height: 16),
          Expanded(
            child: Card(
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: theme.dividerColor, width: 1),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: envVars.length,
                itemBuilder: (context, index) {
                  final key = envVars.keys.elementAt(index);
                  final value = envVars.values.elementAt(index);
                  return ListTile(
                    title: Text(key, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    subtitle: Text(value, style: TextStyle(fontFamily: 'monospace', color: Colors.green[800])),
                    trailing: Icon(Icons.copy, size: 18, color: theme.hintColor),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text(l10n.envSaveAndRedeploy),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  plant.logs = [];
                  plant.aiInsight = 'AI 분석 대기 중...';
                  cpuData = [FlSpot(0, 5)]; memData = [FlSpot(0, 128)]; _timeCounter = 1.0;
                  _tabController.animateTo(0);
                });
                widget.socket.emit('start-deploy', {
                  'version': '${plant.version} (Env Update)',
                  'description': '환경 변수 업데이트',
                  'id': plant.id, // (Env 업데이트는 기존 앱 대상이므로 id 포함)
                  'isWakeUp': true,
                  'workspaceId': widget.workspaceId
                });
              },
            ),
          )
        ],
      ),
    );
  }

  // "겨울잠" 상태일 때 보여줄 UI ---
  Widget _buildSleepingView() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/pot_sleeping.json', width: 200, height: 200),
            SizedBox(height: 24),
            Text(
              l10n.wakeUpTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              l10n.wakeUpMessage,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(Icons.wb_sunny_outlined, color: Colors.white),
              label: Text(l10n.wakeUpButton, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: StadiumBorder(),
              ),
              onPressed: _wakeUpApp, // (신규) 깨우기 함수 호출
            )
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // (신규) "겨울잠" 상태 분기
    if (plant.status == 'SLEEPING') {
      return Scaffold(
        appBar: AppBar(
          title: Text('${l10n.workbenchTitle} ${plant.version}'),
          actions: [
            ProfileMenuButton(
              currentUser: widget.currentUser,
              userData: widget.userData,
            ),
          ],
        ),
        body: _buildSleepingView(), // <-- "겨울잠" UI 표시
      );
    }

    // (이하) "활성" 상태 UI (기존 5-Tab)
    Color statusBarColor;
    Color statusTextColor;
    if (plant.status == 'FAILED') {
      statusBarColor = Colors.red[50]!;
      statusTextColor = Colors.red[800]!;
    } else {
      statusBarColor = Colors.green[50]!;
      statusTextColor = Colors.green[800]!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.workbenchTitle} ${plant.version}'),
        actions: [
          ProfileMenuButton(
            currentUser: widget.currentUser,
            userData: widget.userData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: Container(
            padding: EdgeInsets.all(8.0),
            color: statusBarColor,
            alignment: Alignment.center,
            child: Text(
              plant.currentStatusMessage,
              style: TextStyle(color: statusTextColor, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: theme.cardColor,
            padding: EdgeInsets.all(10),
            height: 150,
            child: _buildAnimation(),
          ),
          Expanded(
            child: DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1))
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: theme.colorScheme.primary,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.hintColor,
                      isScrollable: true,
                      tabs: [
                        Tab(icon: Icon(Icons.terminal), text: l10n.tabConsole),
                        Tab(icon: Icon(Icons.bar_chart), text: l10n.tabVitals),
                        Tab(icon: Icon(Icons.support_agent), text: l10n.tabAIGardener),
                        Tab(icon: Icon(Icons.public), text: l10n.tabGlobalTraffic),
                        Tab(icon: Icon(Icons.vpn_key), text: l10n.tabEnvironment),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildConsoleArea(),
                        _buildMetricsArea(),
                        _buildStatusArea(),
                        _buildGlobalTrafficArea(),
                        _buildEnvArea(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}