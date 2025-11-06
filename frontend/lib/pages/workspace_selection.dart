import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../widgets/profile_menu.dart';
import '../widgets/workspace_switcher.dart';

class WorkspaceSelectionPage extends StatefulWidget {
  final Function(String, String) onWorkspaceSelected;
  final Function(String) onCreateWorkspace;
  final IO.Socket socket;
  final User currentUser;
  final Map<String, dynamic>? userData;
  final List<dynamic> workspaces;

  const WorkspaceSelectionPage({
    Key? key,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    required this.socket,
    required this.currentUser,
    this.userData,
    required this.workspaces,
  }) : super(key: key);

  @override
  _WorkspaceSelectionPageState createState() => _WorkspaceSelectionPageState();
}

class _WorkspaceSelectionPageState extends State<WorkspaceSelectionPage> {
  // List<dynamic> _workspaces = []; // 서버에서 받은 워크스페이스 목록
  // bool _isLoading = true;
  //
  // @override
  // void initState() {
  //   super.initState();
  //   // 1. 서버에 워크스페이스 목록 요청 (최초 1회)
  //   widget.socket.emit('get-my-workspaces');
  //
  //   // 2. 서버로부터 목록 수신 리스너 등록
  //   widget.socket.on('workspaces-list', _onWorkspacesList);
  //
  //   // 3. 서버가 목록을 갱신하라고 지시할 때 (예: 방금 새 워크스페이스를 만들었을 때)
  //   widget.socket.on('get-my-workspaces', (_) {
  //     print("Refreshing workspace list...");
  //     widget.socket.emit('get-my-workspaces'); // 서버에 목록을 다시 요청
  //   });
  // }
  //
  // @override
  // void dispose() {
  //   // 3. 리스너 제거
  //   widget.socket.off('workspaces-list', _onWorkspacesList);
  //   widget.socket.off('get-my-workspaces');
  //   super.dispose();
  // }
  //
  // // (★★★★★ 신규 ★★★★★: 서버 응답 처리)
  // void _onWorkspacesList(dynamic data) {
  //   if (!mounted) return;
  //   setState(() {
  //     _workspaces = data as List;
  //     _isLoading = false;
  //   });
  // }

  void _showCreateWorkspaceDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("새 워크스페이스 생성"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: "워크스페이스 이름"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("취소")),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // (★★★★★ 수정 ★★★★★: 부모(AppCore)의 함수 호출)
                widget.onCreateWorkspace(nameController.text);
                Navigator.pop(ctx);
              }
            },
            child: Text("생성"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("워크스페이스 선택"),
        // 워크스페이스 추가 버튼
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "새 워크스페이스 생성",
            onPressed: _showCreateWorkspaceDialog,
          ),
          // (선택 사항: 이 페이지는 목록 그 자체이므로 굳이 버튼이 필요 없을 수 있음)
          // WorkspaceSwitcher(
          //   workspaces: widget.workspaces,
          //   currentWorkspaceId: null, // 선택된 워크스페이스가 없음
          //   onWorkspaceSelected: widget.onWorkspaceSelected,
          //   onCreateWorkspace: _showCreateWorkspaceDialog,
          // ),
          ProfileMenuButton(
            currentUser: widget.currentUser,
            userData: widget.userData,
          )
        ],
      ),
      // 로딩 상태 및 서버 데이터로 ListView 빌드
      body: ListView.builder(
        itemCount: widget.workspaces.length,
        itemBuilder: (context, index) {
          final ws = widget.workspaces[index];
          final String wsName = ws['name'] ?? '이름 없음';

          return ListTile(
            leading: CircleAvatar(
              child: Text(wsName.isNotEmpty ? wsName[0] : 'W'),
            ),
            title: Text(wsName),
            subtitle: Text("ID: ${ws['id']}"),
            onTap: () {
              // 부모(AppCore)의 콜백 함수 호출
              widget.onWorkspaceSelected(ws['id'], ws['name']);
            },
          );
        },
      ),
    );
  }
}