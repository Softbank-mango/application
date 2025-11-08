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
import 'pages/profile.dart';
import 'pages/settings.dart';
import 'pages/deployment.dart';

class AppCore extends StatefulWidget {
  @override
  _AppCoreState createState() => _AppCoreState();
}

enum AppPage { workspaceSelection, shelf, profile, settings, deployment }

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

  Plant? _selectedPlant;
  // AppPage _currentPage = AppPage.workspaceSelection;

  // 로딩 상태를 하나로 통합
  bool _isLoading = true;

  int _currentIndex = 0; // 0: workspaceSelection, 1: shelf, 2: profile, 3: settings, 4: deployment

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
    // socket?.off('get-my-workspaces', _onGetMyWorkspaces);

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
    // socket?.on('get-my-workspaces', _onGetMyWorkspaces);
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
  void _goBackToWorkspaceSelection() {
    setState(() {
      _selectedWorkspaceId = null;
      _selectedWorkspaceName = "";
      _currentIndex = 0;
    });
  }


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
      setState(() {
        _selectedPlant = newPlant;
        _currentIndex = 4; // 배포 페이지로 즉시 이동
      });
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

  // 워크스페이스 선택 시 호출 (Shelf 페이지로)
  void _onWorkspaceSelected(String workspaceId, String workspaceName) {
    socket!.emit('join-workspace', workspaceId);
    setState(() {
      _selectedWorkspaceId = workspaceId;
      _selectedWorkspaceName = workspaceName;
      _currentIndex = 1; // (수정) Shelf 페이지
    });
  }

  // 프로필 페이지로 이동
  void _showProfilePage() {
    setState(() {
      _currentIndex = 2; // (수정) Profile 페이지
    });
  }

  // 프로필에서 대시보드(Shelf)로 복귀
  void _showShelfPage() {
    setState(() {
      _selectedPlant = null; // (선택된 플랜트 해제)

      // (수정) 워크스페이스 ID가 null인지 확인
      if (_selectedWorkspaceId == null) {
        // 선택된 워크스페이스가 없으면 Shelf(1)가 아니라
        // WorkspaceSelection(0)으로 보냅니다.
        _currentIndex = 0;
      } else {
        // 선택된 워크스페이스가 있으면 Shelf(1)로 보냅니다.
        _currentIndex = 1;
      }
    });
  }

// ProfileMenu에서 "워크스페이스 설정" 누르면 Settings로
  void _showSettingsPage() {
    setState(() {
      _currentIndex = 3; // (수정) Settings 페이지
    });
  }

  // SettingsPage에서 "프로필로 돌아가기" 누르면 Profile
  void _goBackToProfile() {
    setState(() {
      _currentIndex = 2; // (수정) Profile 페이지
    });
  }

  void _navigateToDeployment(Plant plant) {
    setState(() {
      _selectedPlant = plant;
      _currentIndex = 4; // (수정) Deployment 페이지
    });
  }

  void _showCreateWorkspaceDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Text(
          '새 워크스페이스 생성',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '워크스페이스 이름',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '이름을 입력해주세요.';
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) return '설명을 입력해주세요.';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // (수정) onCreateWorkspace(..) 대신 _createNewWorkspace 직접 호출
                _createNewWorkspace(nameController.text, descriptionController.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. 로딩 중일 때 (기존과 동일)
    if (_isLoading || _isLoadingWorkspaces || socket == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("서버와 연결 중..."),
            ],
          ),
        ),
      );
    }

    // (L10n은 FAB 텍스트 등에 필요)
    final l10n = AppLocalizations.of(context)!;

    // 2. 로딩 완료 시 (공통 Scaffold)
    return Scaffold(
      // --- (공통 TopBar) ---
      appBar: TopBar(
        currentUser: _currentUser!,
        userData: _userData,
        workspaces: _workspaces,
        selectedWorkspaceId: _selectedWorkspaceId,
        selectedWorkspaceName: _selectedWorkspaceName,
        isLoading: _isLoadingWorkspaces,
        onLogout: _onLogout,
        goBackToWorkspaceSelection: _goBackToWorkspaceSelection,
        onWorkspaceSelected: _onWorkspaceSelected,
        onCreateWorkspace: () => _showCreateWorkspaceDialog(context),
        onShowProfile: _showProfilePage,
        onShowSettings: _showSettingsPage,
      ),
      // --- (상태에 따라 바뀌는 body) ---
      body: buildBody(),
      // --- (Shelf 페이지일 때만 보이는 FAB) ---
      floatingActionButton: Visibility(
        // 2. _currentPage 상태에 따라 보이기/숨기기
        visible: _currentIndex == 1,

        // 3. 자식 위젯은 항상 존재 (null이 아님)
        child: FloatingActionButton.extended(
          key: const ValueKey('fab-shelf'), // (Key는 혹시 모르니 그대로 둡니다)
          onPressed: () => _startNewDeployment(context, _selectedWorkspaceId!),
          label: Text(l10n.deployNewApp),
          icon: Icon(Icons.add),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: StadiumBorder(),
        ),
      ),
    );
  }

// (신규) body 빌드 헬퍼 함수
  Widget buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: [
        // --- Index 0: workspaceSelection ---
        WorkspaceSelectionPage(
          currentUser: _currentUser!,
          userData: _userData,
          workspaces: _workspaces,
          onCreateWorkspace: (name, description) => _createNewWorkspace(name, description),
          onLogout: _onLogout,
          onWorkspaceSelected: _onWorkspaceSelected,
        ),

        // --- Index 1: shelf ---
        // (수정) _selectedWorkspaceId가 null일 때를 대비해 Builder로 감쌉니다.
        Builder(
            builder: (context) {
              // 워크스페이스가 아직 선택되지 않았다면(null),
              // ShelfPage를 빌드하지 않고 간단한 Placeholder를 반환합니다.
              if (_selectedWorkspaceId == null) {
                // 이 위젯은 어차피 _currentIndex가 0일 때는 보이지 않으므로
                // 로딩 인디케이터나 간단한 텍스트를 반환해도 됩니다.
                return const Center(child: CircularProgressIndicator());
              }

              // _selectedWorkspaceId가 선택되었다면(null이 아님) ShelfPage를 정상 빌드합니다.
              return ShelfPage(
                currentUser: _currentUser!,
                userData: _userData,
                workspaceId: _selectedWorkspaceId!, // (이제 null이 아님을 확신)
                workspaceName: _selectedWorkspaceName,
                socket: socket!,
                workspaces: _workspaces,
                onCreateWorkspace: (name, description) => _createNewWorkspace(name, description),
                onDeploy: () => _startNewDeployment(context, _selectedWorkspaceId!),
                onPlantTap: (plant) {
                  if (plant.status == 'SLEEPING') {
                    socket!.emit('start-deploy', {
                      'id': plant.id, 'isWakeUp': true, 'workspaceId': _selectedWorkspaceId!
                    });
                  }
                  _navigateToDeployment(plant);
                },
                onSlackReaction: (id, emoji) => _sendSlackReaction(id, emoji),
              );
            }
        ),

        // --- Index 2: profile ---
        ProfilePage(
          currentUser: _currentUser!,
          userData: _userData,
          onGoBackToDashboard: _showShelfPage,
        ),

        // --- Index 3: settings ---
        SettingsPage(
          onGoBackToProfile: _goBackToProfile,
        ),

        // --- Index 4: deployment ---
        // (이 부분은 이미 Builder로 잘 처리되어 있습니다)
        Builder(
            builder: (context) {
              if (_selectedPlant == null) {

                // (수정)
                // 현재 페이지가 4(Deployment)가 아니면 튕겨내지 않도록 수정
                if (_currentIndex == 4) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showShelfPage(); // 현재 4번 페이지에 머무르려고 할 때만 튕겨냄
                  });
                }
                return const Center(child: Text("앱을 선택해주세요..."));
              }

              // _selectedPlant가 null이 아니면 정상적으로 페이지를 빌드
              return DeploymentPage(
                plant: _selectedPlant!,
                socket: socket!,
                currentUser: _currentUser!,
                userData: _userData,
                workspaceId: _selectedWorkspaceId!,
                onGoBackToDashboard: _showShelfPage,
                onShowSettings: _showSettingsPage,
              );
            }
        ),
      ],
    );
  }
}
