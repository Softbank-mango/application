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
import 'models/workspace.dart';
import 'models/user_data.dart';
import 'widgets/top_bar.dart';

class AppCore extends StatefulWidget {
  @override
  _AppCoreState createState() => _AppCoreState();
}

class _AppCoreState extends State<AppCore> {
  IO.Socket? socket;
  List<Plant> shelf = []; // (참고: 이 변수는 AppCore가 아닌 ShelfPage로 이동했습니다)
  final player = AudioPlayer();

  List<LogEntry> globalLogs = [];
  Map<String, double> currentMetrics = {'cpu': 0.0, 'mem': 0.0};
  List<FlSpot> cpuData = [FlSpot(0, 5)];
  List<FlSpot> memData = [FlSpot(0, 128)];
  double _timeCounter = 1.0;

  User? _currentUser;
  UserData? _userData;

  List<Workspace> _workspaces = [];
  bool _isLoadingWorkspaces = true;

  String? _selectedWorkspaceId;
  String _selectedWorkspaceName = "";

  // 로딩 상태를 하나로 통합
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAll();
  }

// 통합 초기화 함수
  Future<void> _initializeAll() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("오류: AppCore 진입했으나 사용자 null. 강제 로그아웃.");
      FirebaseAuth.instance.signOut();
      return;
    }

    String? token;
    try {
      token = await user.getIdToken();
    } catch (e) {
      print("토큰 가져오기 실패: $e. 강제 로그아웃.");
      FirebaseAuth.instance.signOut();
      return;
    }

    if (token == null) {
      print("토큰이 null입니다. 강제 로그아웃.");
      FirebaseAuth.instance.signOut();
      return;
    }

    DocumentSnapshot<Map<String, dynamic>>? userDataDoc;
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      userDataDoc = await docRef.get();
    } catch (e) {
      print("Firestore 사용자 정보 로드 실패: $e");
    }

    // (중요) 토큰을 가져온 후에 소켓 연결
    await connectToSocket(token);

    // (신규) 소켓 연결 후 워크스페이스 목록 바로 요청
    socket?.emit('get-my-workspaces');

    if (mounted) {
      setState(() {
        _currentUser = user;
        if (userDataDoc != null && userDataDoc.exists) {
          _userData = UserData.fromFirestore(userDataDoc);
        }
        _isLoading = false; // (로딩 완료)
      });
    }
  }


  // 모든 리스너를 socket.off로 제거
  @override
  void dispose() {
    socket?.off('new-plant', _onNewPlant);
    // socket?.off('plant-update', _onPlantUpdate);
    socket?.off('new-log', _onNewLog);
    // socket?.off('status-update', _onStatusUpdate);
    // socket?.off('reaction-update', _onReactionUpdate);
    socket?.off('metrics-update', _onMetricsUpdate);
    socket?.off('workspaces-list', _onWorkspacesList);
    socket?.off('get-my-workspaces', _onGetMyWorkspaces);

    socket?.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> connectToSocket(String token) async {
    String hostUrl;
    if (kIsWeb) {
      final uri = Uri.base.origin;
      hostUrl = kDebugMode ? 'http://localhost:8080' : uri.toString();
    } else {
      hostUrl = 'https://deplight-softbank.asia-northeast3.run.app';
    }

    socket = IO.io(hostUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token // (전달받은 토큰 사용)
      }
    });

    socket?.on('new-plant', _onNewPlant);
    // socket?.on('plant-update', _onPlantUpdate); // (삭제)
    socket?.on('new-log', _onNewLog);
    // socket?.on('status-update', _onStatusUpdate); // (삭제)
    // socket?.on('reaction-update', _onReactionUpdate); // (삭제)
    socket?.on('metrics-update', _onMetricsUpdate);
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
      name: data['name'] ?? data['version'] ?? 'New App',
      githubUrl: data['githubUrl'] ?? data['description'] ?? '',
      status: data['status'], // (예: "DEPLOYING")
      lastDeployedAt: Timestamp.now(),
      cpuUsage: 0.0,
      memUsage: 0.0,
      ownerUid: data['ownerUid'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      reactions: [],
      // DeploymentPage용 필드 초기화
      logs: [], // 빈 로그 리스트로 시작
      aiInsight: 'AI 분석 대기 중...', // 기본 AI 메시지
      currentStatusMessage: data['message'] ?? '배포 시작 중...',
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
      // AppCore는 'global' 로그(id: 0)만 처리
      if (data['id'] == 0) {
        globalLogs.add(log);
        if (globalLogs.length > 100) globalLogs.removeAt(0);
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
    if (!mounted) return;
    setState(() {
      _workspaces = (data as List).map((ws) => Workspace.fromMap(ws)).toList();
      _isLoadingWorkspaces = false;
    });
  }

  void _onGetMyWorkspaces(dynamic data) {
    if (!mounted) return;
    setState(() { _isLoadingWorkspaces = true; });
    socket?.emit('get-my-workspaces');
  }

  void _createNewWorkspace(String name, String description) {
    if (socket == null || name.isEmpty || description.isEmpty) return;
    socket!.emit('create-workspace', {
      'name': name,
      'description': description
    });
  }

  void _onLogout() {
    FirebaseAuth.instance.signOut();
  }

  void _startNewDeployment(BuildContext context, String workspaceId) {
    if (socket == null) return;

    final gitUrlController = TextEditingController();
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
            TextField(
              controller: gitUrlController,
              decoration: InputDecoration(
                  labelText: 'Git Repository URL *', // (필수 항목)
                  hintText: 'https://github.com/user/repo.git'
              ),
              autofocus: true,
            ),
            SizedBox(height: 10),
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'App Name (v1.5)')),
            TextField(controller: descController, decoration: InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
              onPressed: () {
                final gitUrl = gitUrlController.text.trim();
                if (gitUrl.isEmpty || !gitUrl.startsWith('https://')) {
                  // (간단한 유효성 검사)
                  // (실제로는 gitUrlController 옆에 에러 텍스트를 보여주는 것이 더 좋음)
                  print("Git URL이 유효하지 않습니다.");
                  return;
                }

                final newName = nameController.text.isNotEmpty ? nameController.text : 'New App';
                final newDesc = descController.text.isNotEmpty ? descController.text : 'New deployment...';
                Navigator.pop(ctx);

                socket!.emit('start-deploy', {
                  'gitUrl': gitUrl,
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

  void _goBackToWorkspaceSelection() {
    // (필요 시 'leave-workspace' 소켓 이벤트 emit)
    // socket?.emit('leave-workspace', _selectedWorkspaceId);
    setState(() {
      _selectedWorkspaceId = null;
      _selectedWorkspaceName = "";
    });
  }

  // (신규) TopBar 또는 WorkspaceSelectionPage에서 워크스페이스를 선택했을 때 호출할 함수
  void _onWorkspaceSelected(String workspaceId, String workspaceName) {
    socket!.emit('join-workspace', workspaceId);
    setState(() {
      _selectedWorkspaceId = workspaceId;
      _selectedWorkspaceName = workspaceName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isLoadingWorkspaces || socket == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("서버와 연결 중..."), // (로딩 텍스트 통일)
            ],
          ),
        ),
      );
    }

    return Scaffold(
      // 1. TopBar를 appBar에 배치
      appBar: TopBar(
        currentUser: _currentUser!,
        userData: _userData,
        workspaces: _workspaces,
        selectedWorkspaceId: _selectedWorkspaceId, // (신규 상태)
        selectedWorkspaceName: _selectedWorkspaceName, // (신규 상태)
        isLoading: _isLoadingWorkspaces,
        onLogout: _onLogout,
        goBackToWorkspaceSelection: _goBackToWorkspaceSelection, // (신규 함수)
        onWorkspaceSelected: _onWorkspaceSelected, // (신규 함수)
        onCreateWorkspace: () => _createNewWorkspace("", ""), // (임시, _showCreateWorkspaceDialog 호출로 변경 필요)
      ),
      // 2. body를 상태에 따라 교체
      body: _selectedWorkspaceId == null
          ? WorkspaceSelectionPage(
        // (기존 코드에서 Scaffold와 상단 Row가 제거되어야 함)
        currentUser: _currentUser!,
        userData: _userData,
        workspaces: _workspaces,
        onCreateWorkspace: (name, description) => _createNewWorkspace(name, description),
        onLogout: _onLogout, // (TopBar가 처리하지만, 만약을 위해 유지하거나 제거)
        onWorkspaceSelected: _onWorkspaceSelected, // (Navigator.push 대신 신규 함수 사용)
      )
          : ShelfPage(
        // 3. Navigator.push 대신 body에 직접 ShelfPage 렌더링
        currentUser: _currentUser!,
        userData: _userData,
        workspaceId: _selectedWorkspaceId!,
        workspaceName: _selectedWorkspaceName,
        socket: socket!,
        workspaces: _workspaces,
        onCreateWorkspace: (name, description) => _createNewWorkspace(name, description),
        onDeploy: () => _startNewDeployment(context, _selectedWorkspaceId!),
        onPlantTap: (plant) {
          // (기존 onPlantTap 로직)
        },
        onSlackReaction: (id, emoji) => _sendSlackReaction(id, emoji),
      ),
    );
  }
}