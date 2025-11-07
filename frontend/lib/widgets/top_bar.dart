import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';
import '../models/workspace.dart';
import 'profile_menu.dart';
import 'workspace_switcher.dart';
import '../pages/profile.dart';

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
  final VoidCallback onShowProfile;

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
    required this.onShowProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // (1) 워크스페이스 '선택 전' (기존과 100% 동일)
    if (selectedWorkspaceId == null) {
      return AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 로고
              Row(
                children: [
                  // (로고 이미지는 'logo_small.png' 또는 'deplight_logo_52.png' 등 올바른 경로로 수정하세요)
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
              // 로그아웃 버튼
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

    // --- (수정) ---
    // (2) 워크스페이스 '선택 후' (applist.jpg 이미지와 100% 일치)
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      // (수정) 뒤로가기 버튼 제거
      automaticallyImplyLeading: false,

      // (수정) title 영역에 로고 + WorkspaceSwitcher 배치
      titleSpacing: 48.0, // 왼쪽 패딩
      title: Row(
        children: [
          // 로고
          Image.asset('assets/logo_small.png', height: 32, width: 32, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Text(
            'Deplight',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),

          // 구분선
          const SizedBox(width: 16),
          VerticalDivider(width: 1, thickness: 1, indent: 16, endIndent: 16, color: Colors.grey[300]),
          const SizedBox(width: 16),

          // WorkspaceSwitcher (actions에서 title로 이동)
          if (!isLoading)
            WorkspaceSwitcher(
              workspaces: workspaces,
              currentWorkspaceId: selectedWorkspaceId,
              currentWorkspaceName: selectedWorkspaceName,
              onWorkspaceSelected: onWorkspaceSelected,
              onCreateWorkspace: onCreateWorkspace,
            ),
        ],
      ),

      // (수정) actions에 검색, 알림, 프로필 메뉴 배치
      actions: [
        // 검색 아이콘
        IconButton(
          icon: Icon(Icons.search, color: Colors.grey[600]),
          onPressed: () { /* TODO: 검색 기능 구현 */ },
          tooltip: '검색',
        ),

        // 알림 아이콘
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
          onPressed: () { /* TODO: 알림 기능 구현 */ },
          tooltip: '알림',
        ),

        // 프로필 메뉴
        if (!isLoading)
          ProfileMenuButton(
            currentUser: currentUser,
            userData: userData,
            onLogout: onLogout,
            onShowProfile: onShowProfile,
          ),

        const SizedBox(width: 24), // 오른쪽 끝 패딩
      ],
    );
  }

  // (수정) '선택 후' AppBar 높이를 kToolbarHeight(표준)로 사용
  @override
  Size get preferredSize => Size.fromHeight(selectedWorkspaceId == null ? 80.0 : kToolbarHeight);
}