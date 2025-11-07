import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';
import '../models/workspace.dart';
import 'profile_menu.dart';
import 'workspace_switcher.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  // --- 상태 데이터 ---
  final User currentUser;
  final UserData? userData;
  final List<Workspace> workspaces;
  final String? selectedWorkspaceId;
  final String selectedWorkspaceName;
  final bool isLoading;

  // --- 콜백 함수 ---
  final VoidCallback onLogout;
  final VoidCallback goBackToWorkspaceSelection;
  final Function(String, String) onWorkspaceSelected;
  final VoidCallback onCreateWorkspace;

  // --- 임시 색상 (테마에서 가져오는 것이 좋음) ---
  final Color _textColor = const Color(0xFF333333);
  final Color _tossPrimary = const Color(0xFF678AFB);

  const TopBar({
    Key? key,
    required this.currentUser,
    this.userData,
    required this.workspaces,
    this.selectedWorkspaceId,
    required this.selectedWorkspaceName,
    required this.isLoading,
    required this.onLogout,
    required this.goBackToWorkspaceSelection,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // (1) 워크스페이스 '선택 전' (이미지 상단과 100% 일치)
    if (selectedWorkspaceId == null) {
      return AppBar(
        toolbarHeight: 80, // 높이 조절
        backgroundColor: Colors.transparent, // 그라데이션 배경 보이게
        elevation: 0,
        // (패딩 조절을 위해 title을 수동으로 배치)
        automaticallyImplyLeading: false, // (뒤로가기 버튼 숨김)
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 로고
              Row(
                children: [
                  Image.asset('assets/logo_small.png', height: 40, width: 40, fit: BoxFit.contain),
                  const SizedBox(width: 8),
                  Text(
                    'Deplight',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              // 로그아웃 버튼 (이미지와 100% 일치)
              TextButton.icon(
                onPressed: onLogout,
                icon: Icon(Icons.logout, size: 18, color: _textColor),
                label: Text(
                  '로그아웃',
                  style: textTheme.bodyMedium?.copyWith(color: _textColor, fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: _tossPrimary.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // (2) 워크스페이스 '선택 후' (ShelfPage의 AppBar)
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: goBackToWorkspaceSelection, // (AppCore의 함수 호출)
      ),
      title: Text(selectedWorkspaceName),
      actions: [
        if (!isLoading)
          WorkspaceSwitcher(
            workspaces: workspaces,
            currentWorkspaceId: selectedWorkspaceId,
            currentWorkspaceName: selectedWorkspaceName,
            onWorkspaceSelected: onWorkspaceSelected, // (AppCore의 함수 호출)
            onCreateWorkspace: onCreateWorkspace, // (AppCore의 함수 호출)
          ),
        if (!isLoading)
          ProfileMenuButton(
            currentUser: currentUser,
            userData: userData,
            onLogout: onLogout, // (AppCore의 함수 호출)
          ),
      ],
    );
  }

  // AppBar의 기본 높이(kToolbarHeight) 또는 지정한 높이(80)를 반환합니다.
  @override
  Size get preferredSize => Size.fromHeight(selectedWorkspaceId == null ? 80.0 : kToolbarHeight);
}