import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class AppCore extends StatefulWidget {
  @override
  _AppCoreState createState() => _AppCoreState();
}

class _AppCoreState extends State<AppCore> {
  // 'late' 대신 Nullable 'IO.Socket?'로 변경
  IO.Socket? socket;
  List<Plant> shelf = []; // 실시간 장식장
  final player = AudioPlayer();

  List<LogEntry> globalLogs = [];
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  @override
  void initState() {
    super.initState();
    // 비동기 초기화 함수 호출
    _initializeSocket();
  }

  // 소켓 비동기 초기화 함수
  Future<void> _initializeSocket() async {
    // connectToSocket이 완료되길 기다림 (토큰 받아오기 등)
    await connectToSocket();

    // (중요) 소켓이 초기화된 후, 위젯을 다시 빌드하도록 setState 호출
    if (mounted) {
      setState(() {
        // 이 setState 호출로 build 메서드가 다시 실행되며,
        // socket이 더 이상 null이 아니므로 WorkspaceSelectionPage가 로드됩니다.
      });
    }
  }

  // 모든 리스너를 socket.off로 제거
  @override
  void dispose() {
    socket?.off('current-shelf', _onCurrentShelf);
    socket?.off('new-plant', _onNewPlant);
    socket?.off('plant-update', _onPlantUpdate);
    socket?.off('new-log', _onNewLog);
    socket?.off('status-update', _onStatusUpdate);
    socket?.off('plant-complete', _onPlantComplete);
    socket?.off('reaction-update', _onReactionUpdate);
    socket?.off('metrics-update', _onMetricsUpdate);

    socket?.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> connectToSocket() async {
    String? token;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      token = await user.getIdToken();
    }
    if (token == null) {
      print("로그인 사용자 없음. 소켓 연결 안함.");
      return; // 토큰 없으면 연결 시도 안함
    }

    String hostUrl;
    if (kIsWeb) {
      final uri = Uri.base.origin;
      hostUrl = kDebugMode ? 'http://localhost:8080' : uri.toString();
    } else {
      // 'deplight-softbank' 프로젝트 URL로 변경해야 할 수도 있습니다.)
      hostUrl = 'https://deplight-82312839239.asia-northeast3.run.app';
    }

    socket = IO.io(hostUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token
      }
    });

    // 익명 콜백 대신 별도로 분리된 메소드를 연결
    socket?.on('current-shelf', _onCurrentShelf);
    socket?.on('new-plant', _onNewPlant);
    socket?.on('plant-update', _onPlantUpdate);
    socket?.on('new-log', _onNewLog);
    socket?.on('status-update', _onStatusUpdate);
    socket?.on('plant-complete', _onPlantComplete);
    socket?.on('reaction-update', _onReactionUpdate);
    socket?.on('metrics-update', _onMetricsUpdate);

    // 워크스페이스 관련 리스너 추가
    socket?.on('workspaces-list', _onWorkspacesList);
    socket?.on('get-my-workspaces', _onGetMyWorkspaces);
  }


  // 모든 소켓 리스너를 별도 메소드로 분리 ---
  // (모든 함수 상단에 if (!mounted) return; 안전장치 추가)

  void _onCurrentShelf(dynamic data) {
    if (!mounted) return;
    setState(() {
      shelf = (data as List).map((p) => Plant(
          id: p['id'], plant: p['plant'], version: p['version'],
          description: p['description'] ?? 'No description provided.',
          status: p['status'],
          // (DB 구조 변경으로 owner 필드가 없을 수 있음. Null 처리 필요)
          owner: p['owner'] ?? 'Unknown',
          reactions: List<String>.from(p['reactions'])
      )..currentStatusMessage = (p['status'] == 'HEALTHY' ? '배포 완료됨' : (p['status'] == 'FAILED' ? '배포 실패함' : (p['status'] == 'SLEEPING' ? '겨울잠 상태' : '대기 중')))
      ).toList();
    });
  }

  void _onNewPlant(dynamic data) {
    if (!mounted) return;
    final newPlant = Plant(
        id: data['id'], plant: data['plant'], version: data['version'],
        description: data['description'] ?? 'New deployment...',
        status: data['status'],
        owner: data['owner'] ?? 'Unknown',
        reactions: []
    );
    setState(() {
      shelf.add(newPlant);
    });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeploymentPage(
            plant: newPlant,
            socket: socket!, // (이 시점엔 socket이 null이 아님을 확신)
            initialMetrics: currentMetrics,
            initialCpuData: cpuData,
            initialMemData: memData,
            globalLogs: globalLogs,
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.settings.name != '/loading');
    }
  }

  void _onPlantUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      try {
        final plant = shelf.firstWhere((p) => p.id == data['id']);
        plant.status = data['status'];
        plant.version = data['version'] ?? plant.version;
        plant.plant = data['plant'] ?? plant.plant;
        if(plant.status == 'SLEEPING') plant.currentStatusMessage = '겨울잠 상태';
      } catch (e) { print('Update for unknown plant: ${data['id']}'); }
    });
  }

  void _onNewLog(dynamic data) {
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
  }

  void _onStatusUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      try {
        final plant = shelf.firstWhere((p) => p.id == data['id']);
        plant.status = data['status'];
        plant.currentStatusMessage = data['message'];
      } catch (e) { print('Status for unknown plant: ${data['id']}'); }
    });
  }

  void _onPlantComplete(dynamic data) {
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
  }

  void _onReactionUpdate(dynamic data) {
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
  }

  void _onMetricsUpdate(dynamic data) {
    if (!mounted) return;
    setState(() {
      double cpu = data['cpu'].toDouble(); double mem = data['mem'].toDouble();
      currentMetrics = {'cpu': cpu, 'mem': mem};
      cpuData.add(FlSpot(_timeCounter, cpu)); memData.add(FlSpot(_timeCounter, mem));
      if (cpuData.length > 20) cpuData.removeAt(0); if (memData.length > 20) memData.removeAt(0);
      _timeCounter += 1.0;
    });
  }

  // 워크스페이스 리스너 콜백
  // (WorkspaceSelectionPage로 이동해야 할 수도 있음)
  void _onWorkspacesList(dynamic data) {
    // 이 콜백은 WorkspaceSelectionPage가 직접 처리하도록 위임하는 것이 좋습니다.
    // 여기서는 AppCore가 목록을 관리하지 않으므로 비워둡니다.
  }

  void _onGetMyWorkspaces(dynamic data) {
    // 서버가 목록 갱신을 요청할 때 사용 (WorkspaceSelectionPage가 처리)
  }

  // socket null check 및 workspaceId 전달
  void _startNewDeployment(BuildContext context, String workspaceId) {
    if (socket == null) return; // 소켓이 준비 안됐으면 무시

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

                socket!.emit('start-deploy', {
                  'version': newName,
                  'description': newDesc,
                  'isWakeUp': false,
                  'workspaceId': workspaceId // (중요)
                });

                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => DeploymentLoadingPage(),
                    settings: RouteSettings(name: '/loading')
                ));
              },
              child: Text(l10n.deployNewApp)),
        ],
      ),
    );
  }

  // socket null check
  void _sendSlackReaction(int id, String emoji) {
    if (socket == null) return; // 소켓이 준비 안됐으면 무시
    socket!.emit('slack-reaction', {'id': id, 'emoji': emoji});
  }

  @override
  Widget build(BuildContext context) {
    // socket이 초기화되기 전이면 로딩 화면 표시
    if (socket == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("백엔드 서버와 연결 중..."),
            ],
          ),
        ),
      );
    }

    // (socket이 null이 아닐 때만 WorkspaceSelectionPage를 빌드)
    return WorkspaceSelectionPage(
      socket: socket!, // (null check 했으므로 '!' 사용)
      onWorkspaceSelected: (workspaceId, workspaceName) {

        socket!.emit('join-workspace', workspaceId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShelfPage(
              workspaceId: workspaceId,
              workspaceName: workspaceName,
              shelf: shelf,
              onDeploy: () => _startNewDeployment(context, workspaceId),
              onPlantTap: (plant) {

                if (plant.status == 'SLEEPING') {
                  // (서버에 깨우기 이벤트 전송)
                  socket!.emit('start-deploy', {
                    'id': plant.id,
                    'isWakeUp': true,
                    'workspaceId': workspaceId
                  });

                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DeploymentLoadingPage(),
                      settings: RouteSettings(name: '/loading')
                  ));

                } else {
                  // (기존 배포 상세 페이지 이동 로직)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeploymentPage(
                        plant: plant,
                        socket: socket!,
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