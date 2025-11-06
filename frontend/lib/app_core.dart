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
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // List<Plant> shelf = [];
  final player = AudioPlayer();

  List<LogEntry> globalLogs = [];
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  User? _currentUser;
  Map<String, dynamic>? _userData; // (Firestore의 'users' 문서 데이터)
  bool _isLoadingUser = true; // (로딩 상태)

  @override
  void initState() {
    super.initState();
    // 비동기 초기화 함수 호출
    _initializeSocket();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 1. Auth에서 현재 사용자 가져오기
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("오류: AppCore에 진입했으나 사용자가 null입니다.");
      FirebaseAuth.instance.signOut(); // 강제 로그아웃
      return;
    }

    // 2. Firestore에서 'users' 컬렉션의 추가 정보(role 등) 가져오기
    DocumentSnapshot<Map<String, dynamic>>? userDataDoc;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      userDataDoc = await docRef.get();
    } catch (e) {
      print("Firestore 사용자 정보 로드 실패: $e");
    }

    // 3. 상태 변수에 저장하고 UI 갱신 (로딩 완료)
    if (mounted) {
      setState(() {
        _currentUser = user;
        _userData = userDataDoc?.data();
        _isLoadingUser = false;
      });
    }
  }

  // 소켓 비동기 초기화 함수
  Future<void> _initializeSocket() async {
    await connectToSocket();
    if (mounted) {
      setState(() {
        // 소켓 초기화 완료
      });
    }
  }

  // 모든 리스너를 socket.off로 제거
  @override
  void dispose() {
    socket?.off('new-plant', _onNewPlant);
    socket?.off('plant-update', _onPlantUpdate);
    socket?.off('new-log', _onNewLog);
    socket?.off('status-update', _onStatusUpdate);
    socket?.off('reaction-update', _onReactionUpdate);
    socket?.off('metrics-update', _onMetricsUpdate);
    socket?.off('workspaces-list', _onWorkspacesList);
    socket?.off('get-my-workspaces', _onGetMyWorkspaces);

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
      return;
    }

    String hostUrl;
    if (kIsWeb) {
      final uri = Uri.base.origin;
      hostUrl = kDebugMode ? 'http://localhost:8080' : uri.toString();
    } else {
      // deplight-softbank 프로젝트 URL이 맞는지 확인 필요 (TODO)
      hostUrl = 'https://deplight-softbank.asia-northeast3.run.app';
    }

    socket = IO.io(hostUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token
      }
    });

    socket?.on('new-plant', _onNewPlant);
    socket?.on('plant-update', _onPlantUpdate);
    socket?.on('new-log', _onNewLog);
    socket?.on('status-update', _onStatusUpdate);
    socket?.on('reaction-update', _onReactionUpdate);
    socket?.on('metrics-update', _onMetricsUpdate);

    // 워크스페이스 관련 리스너 (WorkspaceSelectionPage로 이동 예정)
    socket?.on('workspaces-list', _onWorkspacesList);
    socket?.on('get-my-workspaces', _onGetMyWorkspaces);
  }

  // _onCurrentShelf 메소드 전체
  /*
  void _onCurrentShelf(dynamic data) {
    if (!mounted) return;
    setState(() {
      shelf = ...
    });
  }
  */


  void _onNewPlant(dynamic data) {
    if (!mounted) return;

    final String workspaceId = data['workspaceId'];

    final newPlant = Plant(
        id: data['id'],
        plantType: data['plantType'] ?? 'pot',
        version: data['version'],
        description: data['description'] ?? 'New deployment...',
        status: data['status'],
        ownerUid: data['ownerUid'],
        workspaceId: data['workspaceId'],
        reactions: []
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeploymentPage(
            plant: newPlant,
            socket: socket!,
            initialMetrics: currentMetrics,
            initialCpuData: cpuData,
            initialMemData: memData,
            globalLogs: globalLogs,
            currentUser: _currentUser!,
            userData: _userData,
            workspaceId: workspaceId,
          ),
        ),
      );
      Navigator.of(context).popUntil((route) => route.settings.name != '/loading');
    }
  }

  void _onPlantUpdate(dynamic data) {
    if (!mounted) return;
    // shelf 변수가 없으므로 이 로직은 이제 ShelfPage에서 처리되어야 함
    /*
    setState(() {
      try {
        final plant = shelf.firstWhere((p) => p.id == data['id']);
        plant.status = data['status'];
        plant.version = data['version'] ?? plant.version;
        plant.plantType = data['plantType'] ?? plant.plantType;
        if(plant.status == 'SLEEPING') plant.currentStatusMessage = '겨울잠 상태';
      } catch (e) { print('Update for unknown plant: ${data['id']}'); }
    });
    */
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
        // (참고: shelf 변수가 없으므로 이 로직은 이제 ShelfPage 또는 DeploymentPage에서 처리되어야 함)
        /*
        try {
          final plant = shelf.firstWhere((p) => p.id == data['id']);
          plant.logs.add(log);
          if (log.status == 'AI_INSIGHT') plant.aiInsight = log.message;
        } catch (e) { print('Log for unknown plant: ${data['id']}'); }
        */
      }
    });
  }

  void _onStatusUpdate(dynamic data) {
    if (!mounted) return;
    // shelf 변수가 없으므로 이 로직은 이제 ShelfPage 또는 DeploymentPage에서 처리되어야 함
    /*
    setState(() {
      try {
        final plant = shelf.firstWhere((p) => p.id == data['id']);
        plant.status = data['status'];
        plant.currentStatusMessage = data['message'];
      } catch (e) { print('Status for unknown plant: ${data['id']}'); }
    });
    */
  }

  void _onReactionUpdate(dynamic data) {
    if (!mounted) return;
    // shelf 변수가 없으므로 이 로직은 이제 ShelfPage에서 처리되어야 함
    /*
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
    */
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

  void _onWorkspacesList(dynamic data) {
    // (이 콜백은 WorkspaceSelectionPage가 직접 처리)
  }

  void _onGetMyWorkspaces(dynamic data) {
    // (이 콜백은 WorkspaceSelectionPage가 직접 처리)
  }

  void _startNewDeployment(BuildContext context, String workspaceId) {
    if (socket == null) return;

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
                  'workspaceId': workspaceId
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

  void _sendSlackReaction(String id, String emoji) {
    if (socket == null) return;
    socket!.emit('slack-reaction', {'id': id, 'emoji': emoji});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser || socket == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(_isLoadingUser ? "사용자 정보 로드 중..." : "백엔드 서버와 연결 중..."),
            ],
          ),
        ),
      );
    }

    return WorkspaceSelectionPage(
      socket: socket!,
      currentUser: _currentUser!,
      userData: _userData,
      onWorkspaceSelected: (workspaceId, workspaceName) {

        socket!.emit('join-workspace', workspaceId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShelfPage(
              currentUser: _currentUser!,
              userData: _userData,
              workspaceId: workspaceId,
              workspaceName: workspaceName,
              socket: socket!, // socket 전달
              // shelf: shelf,
              onDeploy: () => _startNewDeployment(context, workspaceId),
              onPlantTap: (plant) {
                if (plant.status == 'SLEEPING') {
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
                        currentUser: _currentUser!,
                        userData: _userData,
                        workspaceId: workspaceId,
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