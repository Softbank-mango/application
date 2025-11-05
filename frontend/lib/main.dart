import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// (신규) l10n 및 글로벌 상태 임포트
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'app_state.dart';
import 'theme/app_theme.dart';

// 분리된 파일들 임포트
import 'models/plant_model.dart';
import 'models/logEntry_model.dart';
import 'pages/workspace_selection.dart';
import 'pages/app_list.dart';
import 'pages/deployment.dart';
import 'pages/loading.dart';

void main() => runApp(MyApp());

// --- (1) 앱의 껍데기 (신규 "Toss" 테마) ---
class MyApp extends StatelessWidget {
  // (신규) 글로벌 상태 인스턴스
  final AppState _appState = AppState.instance;

  @override
  Widget build(BuildContext context) {
    // (신규) ValueListenableBuilder로 앱의 테마와 로케일을 실시간 변경
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _appState.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: _appState.locale,
          builder: (context, locale, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Deplight',

              // (신규) l10n 설정
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,

              // (신규) 글로벌 상태에서 로케일 적용
              locale: locale,

              // (신규) AppTheme에서 라이트/다크 모드 테마 적용
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode, // (신규) 글로벌 상태에서 테마 모드 적용

              home: AppCore(),
            );
          },
        );
      },
    );
  }
}

// --- (2) 앱의 핵심 로직 (상태 관리 및 네비게이션) ---
// (이 파일의 나머지 코드는 이전 버전과 100% 동일합니다)
class AppCore extends StatefulWidget {
  @override
  _AppCoreState createState() => _AppCoreState();
}
// ... (이하 _AppCoreState 클래스 코드는 변경 없음) ...
class _AppCoreState extends State<AppCore> {
// ... (이전 코드와 동일) ...
  late IO.Socket socket;
  List<Plant> shelf = [];
// ... (이전 코드와 동일) ...
  final player = AudioPlayer();
  List<LogEntry> globalLogs = [];
// ... (이전 코드와 동일) ...
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  @override
  void initState() {
    super.initState();
// ... (이전 코드와 동일) ...
    connectToSocket();
  }

  @override
  void dispose() {
    socket.dispose();
// ... (이전 코드와 동일) ...
    player.dispose();
    super.dispose();
  }

  void connectToSocket() {
    socket = IO.io('ws://localhost:4000', <String, dynamic>{
// ... (이전 코드와 동일) ...
      'transports': ['websocket'], 'autoConnect': true
    });

    socket.on('current-shelf', (data) {
      if (!mounted) return;
      setState(() {
// ... (이전 코드와 동일) ...
        shelf = (data as List).map((p) => Plant(
            id: p['id'], plant: p['plant'], version: p['version'],
            description: p['description'] ?? 'No description provided.',
            status: p['status'], owner: p['owner'], reactions: List<String>.from(p['reactions'])
        )..currentStatusMessage = (p['status'] == 'HEALTHY' ? '배포 완료됨' : (p['status'] == 'FAILED' ? '배포 실패함' : '대기 중'))
        ).toList();
      });
    });

    socket.on('new-plant', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;

      final newPlant = Plant(
          id: data['id'], plant: data['plant'], version: data['version'],
// ... (이전 코드와 동일) ...
          description: data['description'] ?? 'New deployment...',
          status: data['status'], owner: data['owner'], reactions: []
      );

      setState(() {
        shelf.add(newPlant);
      });

      Navigator.push(
// ... (이전 코드와 동일) ...
        context,
        MaterialPageRoute(
          builder: (context) => DeploymentPage(
            plant: newPlant,
// ... (이전 코드와 동일) ...
            socket: socket,
            initialMetrics: currentMetrics,
            initialCpuData: cpuData,
            initialMemData: memData,
            globalLogs: globalLogs,
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    });

    socket.on('new-log', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;
      setState(() {
        final log = LogEntry(
            time: DateTime.parse(data['log']['time']),
// ... (이전 코드와 동일) ...
            message: data['log']['message'],
            status: data['log']['status']
        );
        if (data['id'] == 0) {
// ... (이전 코드와 동일) ...
          globalLogs.add(log);
          if (globalLogs.length > 100) globalLogs.removeAt(0);
        } else {
          try {
// ... (이전 코드와 동일) ...
            final plant = shelf.firstWhere((p) => p.id == data['id']);
            plant.logs.add(log);
            if (log.status == 'AI_INSIGHT') plant.aiInsight = log.message;
          } catch (e) { print('Log for unknown plant: ${data['id']}'); }
        }
      });
    });

    socket.on('status-update', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
// ... (이전 코드와 동일) ...
          plant.status = data['status'];
          plant.currentStatusMessage = data['message'];
        } catch (e) { print('Status for unknown plant: ${data['id']}'); }
      });
    });

    socket.on('plant-complete', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
// ... (이전 코드와 동일) ...
          plant.status = data['status'];
          plant.plant = data['plant'];
          plant.version = data['version'];
        } catch (e) { print('Complete for unknown plant: ${data['id']}'); }
      });
      player.play(AssetSource('success.mp3'));
    });

    socket.on('reaction-update', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
// ... (이전 코드와 동일) ...
          plant.reactions = List<String>.from(data['reactions']);
          plant.isSparkling = true;
          Future.delayed(Duration(seconds: 2), () {
// ... (이전 코드와 동일) ...
            if (mounted) {
              setState(() => plant.isSparkling = false);
            }
          });
        } catch (e) { print('Reaction for unknown plant: ${data['id']}'); }
      });
    });

    socket.on('metrics-update', (data) {
// ... (이전 코드와 동일) ...
      if (!mounted) return;
      setState(() {
        double cpu = data['cpu'].toDouble(); double mem = data['mem'].toDouble();
// ... (이전 코드와 동일) ...
        currentMetrics = {'cpu': cpu, 'mem': mem};
        cpuData.add(FlSpot(_timeCounter, cpu)); memData.add(FlSpot(_timeCounter, mem));
        if (cpuData.length > 20) cpuData.removeAt(0); if (memData.length > 20) memData.removeAt(0);
// ... (이전 코드와 동일) ...
        _timeCounter += 1.0;
      });
    });
  }

  void _startNewDeployment(BuildContext context) {
// ... (이전 코드와 동일) ...
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final l10n = AppLocalizations.of(context)!; // (신규)

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deployNewApp), // (수정)
        content: Column(
// ... (이전 코드와 동일) ...
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'App Name (v1.5)')),
// ... (이전 코드와 동일) ...
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)), // (수정)
          TextButton(
              onPressed: () {
// ... (이전 코드와 동일) ...
                final newName = nameController.text.isNotEmpty ? nameController.text : 'New App';
                final newDesc = descController.text.isNotEmpty ? descController.text : 'New deployment...';
                Navigator.pop(ctx);
                socket.emit('start-deploy', { 'version': newName, 'description': newDesc });
                Navigator.push(context, MaterialPageRoute(builder: (context) => DeploymentLoadingPage()));
              },
              child: Text(l10n.deployNewApp)), // (수정)
        ],
      ),
    );
  }

  void _sendSlackReaction(int id, String emoji) {
// ... (이전 코드와 동일) ...
    socket.emit('slack-reaction', {'id': id, 'emoji': emoji});
  }

  @override
  Widget build(BuildContext context) {
// ... (이전 코드와 동일) ...
    return WorkspaceSelectionPage(
      onWorkspaceSelected: (workspaceId, workspaceName) {
        Navigator.push(
// ... (이전 코드와 동일) ...
          context,
          MaterialPageRoute(
            builder: (context) => ShelfPage(
              workspaceId: workspaceId,
// ... (이전 코드와 동일) ...
              workspaceName: workspaceName,
              shelf: shelf,
              onDeploy: () => _startNewDeployment(context),
              onPlantTap: (plant) {
// ... (이전 코드와 동일) ...
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeploymentPage(
// ... (이전 코드와 동일) ...
                      plant: plant,
                      socket: socket,
                      initialMetrics: currentMetrics,
// ... (이전 코드와 동일) ...
                      initialCpuData: cpuData,
                      initialMemData: memData,
                      globalLogs: globalLogs,
                    ),
                  ),
                );
              },
              onSlackReaction: (id, emoji) => _sendSlackReaction(id, emoji),
            ),
          ),
        );
      },
    );
  }
}