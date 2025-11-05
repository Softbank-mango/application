import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';
import 'app_state.dart';
import 'theme/app_theme.dart';

import 'models/plant_model.dart';
import 'models/logEntry_model.dart';
import 'pages/workspace_selection.dart';
import 'pages/app_list.dart';
import 'pages/deployment.dart';
import 'pages/loading.dart';

late IO.Socket socket;

void main() => runApp(MyApp());

// --- (1) 앱의 껍데기 (신규 "Toss" 테마) ---
class MyApp extends StatelessWidget {
  final AppState _appState = AppState.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _appState.themeMode,
      builder: (context, themeMode, child) {
        return ValueListenableBuilder<Locale>(
          valueListenable: _appState.locale,
          builder: (context, locale, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Deplight',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: AppCore(),
            );
          },
        );
      },
    );
  }
}

// --- (2) 앱의 핵심 로직 (상태 관리 및 네비게이션) ---
class AppCore extends StatefulWidget {
  @override
  _AppCoreState createState() => _AppCoreState();
}

class _AppCoreState extends State<AppCore> {
  late IO.Socket socket;
  List<Plant> shelf = []; // (핵심) 실시간 장식장
  final player = AudioPlayer();

  List<LogEntry> globalLogs = [];
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
    super.dispose();
  }

  void connectToSocket() {
    String hostUrl;

    if (kIsWeb) {
      // 웹 환경
      // 로컬 개발 시: http://localhost:8080
      // 배포 시: Cloud Run origin 자동 사용
      hostUrl = kDebugMode ? 'http://localhost:8080' : '';
    } else {
      // 모바일 환경
      // Cloud Run 주소 + 포트 8080 (Cloud Run은 실제로 8080 포트로 컨테이너 실행됨)
      hostUrl = 'https://deplight-82312839239.asia-northeast3.run.app';
    }

    socket = IO.io(hostUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    // 1. "장식장" 데이터 수신
    socket.on('current-shelf', (data) {
      if (!mounted) return;
      setState(() {
        shelf = (data as List).map((p) => Plant(
            id: p['id'], plant: p['plant'], version: p['version'],
            description: p['description'] ?? 'No description provided.',
            status: p['status'], owner: p['owner'], reactions: List<String>.from(p['reactions'])
        )..currentStatusMessage = (p['status'] == 'HEALTHY' ? '배포 완료됨' : (p['status'] == 'FAILED' ? '배포 실패함' : (p['status'] == 'SLEEPING' ? '겨울잠 상태' : '대기 중')))
        ).toList();
      });
    });

    // 2. "새 씨앗"이 장식장에 추가됨
    socket.on('new-plant', (data) {
      if (!mounted) return;

      final newPlant = Plant(
          id: data['id'], plant: data['plant'], version: data['version'],
          description: data['description'] ?? 'New deployment...',
          status: data['status'], owner: data['owner'], reactions: []
      );

      setState(() {
        shelf.add(newPlant);
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeploymentPage(
            plant: newPlant,
            socket: socket,
            initialMetrics: currentMetrics,
            initialCpuData: cpuData,
            initialMemData: memData,
            globalLogs: globalLogs,
          ),
        ),
      );

      // 로딩 페이지 닫기 (만약 있었다면)
      Navigator.of(context).popUntil((route) => route.settings.name != '/loading');
    });

    // (신규) 3. "겨울잠" 등 상태 업데이트
    socket.on('plant-update', (data) {
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
          plant.status = data['status'];
          plant.version = data['version'] ?? plant.version;
          plant.plant = data['plant'] ?? plant.plant;
          // 상태 메시지 업데이트
          if(plant.status == 'SLEEPING') plant.currentStatusMessage = '겨울잠 상태';
        } catch (e) { print('Update for unknown plant: ${data['id']}'); }
      });
    });

    // 4. 실시간 로그/상태/AI 수신
    socket.on('new-log', (data) {
      if (!mounted) return;
      setState(() {
        final log = LogEntry(
            time: DateTime.parse(data['log']['time']),
            message: data['log']['message'],
            status: data['log']['status']
        );
        if (data['id'] == 0) {
          globalLogs.add(log);
          if (globalLogs.length > 100) globalLogs.removeAt(0);
        } else {
          try {
            final plant = shelf.firstWhere((p) => p.id == data['id']);
            plant.logs.add(log);
            if (log.status == 'AI_INSIGHT') plant.aiInsight = log.message;
          } catch (e) { print('Log for unknown plant: ${data['id']}'); }
        }
      });
    });

    socket.on('status-update', (data) {
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
          plant.status = data['status'];
          plant.currentStatusMessage = data['message'];
        } catch (e) { print('Status for unknown plant: ${data['id']}'); }
      });
    });

    // 5. 배포 완료 (랜덤 식물)
    socket.on('plant-complete', (data) {
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
          plant.status = data['status'];
          plant.plant = data['plant'];
          plant.version = data['version'];
        } catch (e) { print('Complete for unknown plant: ${data['id']}'); }
      });
      player.play(AssetSource('success.mp3'));
    });

    // 6. Slack 반응 수신
    socket.on('reaction-update', (data) {
      if (!mounted) return;
      setState(() {
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
          plant.reactions = List<String>.from(data['reactions']);
          plant.isSparkling = true;
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() => plant.isSparkling = false);
            }
          });
        } catch (e) { print('Reaction for unknown plant: ${data['id']}'); }
      });
    });

    // 7. 매트릭스 수신 (글로벌)
    socket.on('metrics-update', (data) {
      if (!mounted) return;
      setState(() {
        double cpu = data['cpu'].toDouble(); double mem = data['mem'].toDouble();
        currentMetrics = {'cpu': cpu, 'mem': mem};
        cpuData.add(FlSpot(_timeCounter, cpu)); memData.add(FlSpot(_timeCounter, mem));
        if (cpuData.length > 20) cpuData.removeAt(0); if (memData.length > 20) memData.removeAt(0);
        _timeCounter += 1.0;
      });
    });
  }

  // '새 앱 배포' 로직 (FAB가 호출)
  void _startNewDeployment(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deployNewApp),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'App Name (v1.5)')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
              onPressed: () {
                final newName = nameController.text.isNotEmpty ? nameController.text : 'New App';
                final newDesc = descController.text.isNotEmpty ? descController.text : 'New deployment...';
                Navigator.pop(ctx);
                socket.emit('start-deploy', { 'version': newName, 'description': newDesc, 'isWakeUp': false }); // (수정)
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => DeploymentLoadingPage(),
                    settings: RouteSettings(name: '/loading') // (신규)
                ));
              },
              child: Text(l10n.deployNewApp)),
        ],
      ),
    );
  }

  // Slack 반응 테스트용
  void _sendSlackReaction(int id, String emoji) {
    socket.emit('slack-reaction', {'id': id, 'emoji': emoji});
  }

  @override
  Widget build(BuildContext context) {
    return WorkspaceSelectionPage(
      // (신규) 더미 데이터 대신 AppCore의 "실시간" shelf 리스트를 참조
      getWorkspaces: () {
        // (임시) 워크스페이스 선택은 아직 더미 사용
        return [
          { 'id': 'ws_id_lguplus', 'name': 'LG Uplus', 'icon': 'L' },
          { 'id': 'ws_id_unicef', 'name': '유니세프', 'icon': '유' },
          { 'id': 'ws_id_cjenm', 'name': 'CJ ENM', 'icon': 'C' },
        ];
      },
      onWorkspaceSelected: (workspaceId, workspaceName) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShelfPage(
              workspaceId: workspaceId,
              workspaceName: workspaceName,
              shelf: shelf, // (신규) 실시간 shelf 리스트 전달
              onDeploy: () => _startNewDeployment(context),
              onPlantTap: (plant) {

                // (신규) "겨울잠" 상태일 경우, 배포 페이지가 아닌 "깨우기" 로직 실행
                if (plant.status == 'SLEEPING') {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DeploymentPage(
                        plant: plant, socket: socket, initialMetrics: currentMetrics,
                        initialCpuData: cpuData, initialMemData: memData, globalLogs: globalLogs,
                      )
                  ));
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeploymentPage(
                        plant: plant,
                        socket: socket,
                        initialMetrics: currentMetrics,
                        initialCpuData: cpuData,
                        initialMemData: memData,
                        globalLogs: globalLogs,
                      ),
                    ),
                  );
                }
              },
              onSlackReaction: (id, emoji) => _sendSlackReaction(id, emoji),
            ),
          ),
        );
      },
    );
  }
}