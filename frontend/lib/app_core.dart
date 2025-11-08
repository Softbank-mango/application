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
// import 'pages/loading.dart';
import 'models/workspace.dart';
import 'models/user_data.dart';
import 'widgets/top_bar.dart';
import 'pages/profile.dart';
import 'pages/settings.dart';
import 'pages/deployment.dart';
import 'app_state.dart';
import 'widgets/new_deploy.dart';
import '../widgets/new_workspace.dart';
import 'widgets/deploy_modal.dart';


class AppStateNavBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, NavState navState) builder;
  const AppStateNavBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = AppState.instance;
    return ValueListenableBuilder<int>(
      valueListenable: appState.currentIndex,
      builder: (context, currentIndex, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: appState.selectedWorkspaceId,
          builder: (context, workspaceId, _) {
            return ValueListenableBuilder<String>(
              valueListenable: appState.selectedWorkspaceName,
              builder: (context, workspaceName, _) {
                return ValueListenableBuilder<Plant?>(
                  valueListenable: appState.selectedPlant,
                  builder: (context, plant, _) {
                    return builder(
                      context,
                      NavState(
                        currentIndex: currentIndex,
                        workspaceId: workspaceId,
                        workspaceName: workspaceName,
                        plant: plant,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// 헬퍼 위젯이 사용할 데이터 클래스
class NavState {
  final int currentIndex;
  final String? workspaceId;
  final String workspaceName;
  final Plant? plant;
  NavState({
    required this.currentIndex,
    required this.workspaceId,
    required this.workspaceName,
    required this.plant,
  });
}

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

  // String? _selectedWorkspaceId;
  // String _selectedWorkspaceName = "";

  Plant? _selectedPlant;
  // AppPage _currentPage = AppPage.workspaceSelection;

  // 로딩 상태를 하나로 통합
  bool _isLoading = true;

  // int _currentIndex = 0; // 0: workspaceSelection, 1: shelf, 2: profile, 3: settings, 4: deployment

  final AppState appState = AppState.instance;

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

    if (socket != null) {
      appState.setSocket(socket!);
    }

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
    socket?.off('workspaces-updated', _onWorkspacesUpdated);

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
    socket?.on('workspaces-updated', _onWorkspacesUpdated);
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
  // void _goBackToWorkspaceSelection() {
  //   setState(() {
  //     _selectedWorkspaceId = null;
  //     _selectedWorkspaceName = "";
  //     _currentIndex = 0;
  //   });
  // }


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
      appState.navigateToDeployment(newPlant);
    }
  }

  void _onWorkspacesUpdated(dynamic data) {
    if (!mounted) return;
    print("Workspace list changed on server, re-fetching...");

    // setState(true) 대신, 요청만 수행합니다.
    // 로딩 인디케이터는 _workspaces.isEmpty를 통해 간접적으로 처리하는 것이 더 안전합니다.
    socket?.emit('get-my-workspaces');
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

  void _addSecret(String name, String value, String? description) {
    if (appState.socket == null) {
      print("Socket is not connected.");
      return;
    }
    // 현재 선택된 워크스페이스 ID를 AppState에서 가져옵니다.
    final String? workspaceId = appState.selectedWorkspaceId.value;
    if (workspaceId == null) {
      print("No workspace selected.");
      return;
    }

    appState.socket!.emit('add-secret', {
      'workspaceId': workspaceId,
      'name': name,
      'value': value,
      'description': description,
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

  void _onWorkspacesList(dynamic data) {
    if (!mounted) return;
    setState(() {
      _workspaces = (data as List).map((ws) => Workspace.fromMap(ws)).toList();

      // 데이터 수신 완료 후 로딩 상태를 false로 설정하여 UI를 갱신합니다.
      _isLoadingWorkspaces = false;
    });
  }

  void _createNewWorkspace(String name, String description, String type) {
    if (appState.socket == null) return;
    appState.socket!.emit('create-workspace', {
      'name': name,
      'description': description,
      'type': type,
    });
  }

  void _onLogout() {
    FirebaseAuth.instance.signOut();
  }

  void _startNewDeployment(BuildContext context, String workspaceId) {
    if (socket == null) return;

    showDialog(
      context: context,
      builder: (ctx) => NewDeploymentDialog( // (Git URL 입력창)
        onDeploymentStart: (appName, gitUrl, description) {

          final newName = appName.isNotEmpty ? appName : 'New App';
          final newDesc = description != null && description.isNotEmpty ? description : 'New deployment...';

          socket!.emit('start-deploy', {
            'gitUrl': gitUrl,
            'version': newName,
            'description': newDesc,
            'isWakeUp': false,
            'workspaceId': workspaceId,
          });

          // Git URL 입력창이 닫힌 *직후*에
          // 새로운 'DeployModal' (야구 애니메이션)을 띄웁니다.

          // (삭제) Navigator.push(context, MaterialPageRoute(builder: (context) => DeploymentLoadingPage(), ...));

          // (신규) 배포 진행률 모달을 띄웁니다.
          showDialog(
            context: context,
            barrierDismissible: false, // 배포 중에는 밖을 눌러 닫기 방지
            builder: (deployCtx) => const DeployModal(),
          );
        },
      ),
    );
  }

  void _sendSlackReaction(String id, String emoji) {
    if (socket == null) return;
    socket!.emit('slack-reaction', {'id': id, 'emoji': emoji});
  }

  void _showCreateWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return NewWorkspaceDialog(
          onWorkspaceCreated: (name, description, type) {
            // 1. 워크스페이스 생성 요청 (서버로 emit)
            _createNewWorkspace(name, description, type);
          },
        );
      },
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
    return AppStateNavBuilder(
      builder: (context, navState) {
        return Scaffold(
          // --- (공통 TopBar) ---
          appBar: TopBar(
            currentUser: _currentUser!,
            userData: _userData,
            workspaces: _workspaces,
            isLoading: _isLoadingWorkspaces,
            onLogout: _onLogout,
            onCreateWorkspace: () => _showCreateWorkspaceDialog(context),

            // (수정) AppState에서 가져온 상태와 함수들
            selectedWorkspaceId: navState.workspaceId,
            selectedWorkspaceName: navState.workspaceName,
            goBackToWorkspaceSelection: appState.goBackToWorkspaceSelection,
            onWorkspaceSelected: appState.onWorkspaceSelected,
            onShowProfile: appState.showProfilePage,
            onShowSettings: appState.showSettingsPage,
          ),
          // --- (상태에 따라 바뀌는 body) ---
          body: buildBody(navState), // (수정) buildBody에 navState 전달
        );
      }
    );
  }

// (신규) body 빌드 헬퍼 함수
  Widget buildBody(NavState navState) {
    return IndexedStack(
      index: navState.currentIndex, // (수정)
      children: [
        // --- Index 0: workspaceSelection ---
        WorkspaceSelectionPage(
          currentUser: _currentUser!,
          userData: _userData,
          workspaces: _workspaces,
          onCreateWorkspace: () => _showCreateWorkspaceDialog(context),
          onLogout: _onLogout,
          onWorkspaceSelected: appState.onWorkspaceSelected, // (수정)
        ),

        // --- Index 1: shelf ---
        Builder(
            builder: (context) {
              if (navState.workspaceId == null) { // (수정)
                return const Center(child: CircularProgressIndicator());
              }
              return ShelfPage(
                currentUser: _currentUser!,
                userData: _userData,
                workspaceId: navState.workspaceId!, // (수정)
                workspaceName: navState.workspaceName, // (수정)
                socket: socket!,
                workspaces: _workspaces,
                onCreateWorkspace: () => _showCreateWorkspaceDialog(context),
                onDeploy: () => _startNewDeployment(context, navState.workspaceId!),
                onPlantTap: appState.navigateToDeployment, // (수정)
                onSlackReaction: (id, emoji) => _sendSlackReaction(id, emoji),
              );
            }
        ),

        // --- Index 2: profile ---
        ProfilePage(
          currentUser: _currentUser!,
          userData: _userData,
          onGoBackToDashboard: appState.showShelfPage, // (수정)
        ),

        // --- Index 3: settings ---
        SettingsPage(
          onGoBackToProfile: appState.goBackToProfile, // (수정)
          onAddSecret: _addSecret,
        ),

        // --- Index 4: deployment ---
        Builder(
            builder: (context) {

              // (수정)
              // 튕김 로직(addPostFrameCallback)을 모두 삭제합니다.
              //
              // navState.plant가 null이면,
              // 페이지를 강제로 이동시키는 대신 비어있는 상태를 표시합니다.
              if (navState.plant == null) {
                // 현재 인덱스가 4인데 plant가 null인 비정상적인 상황.
                // 로딩을 보여주거나, 에러 메시지를 보여줍니다.
                return const Center(child: Text("선택된 앱을 불러오는 중..."));
              }

              // navState.plant가 null이 아닐 때만 DeploymentPage를 빌드합니다.
              return DeploymentPage(
                plant: navState.plant!,
                socket: socket!,
                currentUser: _currentUser!,
                userData: _userData,
                // (수정) workspaceId가 null일 수 있으므로 null-check 추가
                workspaceId: navState.workspaceId ?? "",
                onGoBackToDashboard: appState.showShelfPage,
                onShowSettings: appState.showSettingsPage,
              );
            }
        ),
      ],
    );
  }
}
