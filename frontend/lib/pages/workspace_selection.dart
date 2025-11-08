import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp 때문에 필요
import '../models/user_data.dart';
import '../models/workspace.dart'; // (★★ 수정: import)

// (★★ 수정: NewWorkspaceDialog 관련 import 삭제. 이 파일은 몰라도 됨)

class WorkspaceSelectionPage extends StatelessWidget {
  final VoidCallback onCreateWorkspace;
  final VoidCallback onLogout;
  final Function(String, String) onWorkspaceSelected;
  final User currentUser;
  final UserData? userData;

  // (★★ 수정: List<dynamic> -> List<Workspace>)
  final List<Workspace> workspaces;

  const WorkspaceSelectionPage({
    Key? key,
    required this.onCreateWorkspace,
    required this.onLogout,
    required this.onWorkspaceSelected,
    required this.currentUser,
    this.userData,
    required this.workspaces, // (★★ 수정)
  }) : super(key: key);

  // (색상 정의 - 기존과 동일)
  final Color _tossPrimary = const Color(0xFF678AFB);
  final Color _gradientStart = const Color(0xFFEFF6FF);
  final Color _gradientEnd = const Color(0xFFFAF5FF);
  final Color _textColor = const Color(0xFF333333);
  final Color _hintColor = const Color(0xFF999999);
  final Color _cardBackgroundColor = Colors.white;

  // (★★ 수정: 이 위젯에 있으면 안 되는 함수들 삭제)
  // _createNewWorkspace, _showCreateWorkspaceDialog 함수를
  // 이 파일에서 *완전히 삭제*합니다. (AppCore가 담당)

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // (★★ 수정: '!' 느낌표 제거. 관리자만 생성 가능)
    final isUserAdmin = userData?.role == 'admin';

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gradientStart, _gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48.0), // 전체 패딩
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200), // 최대 너비
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 메인 타이틀 ---
                Text(
                  '워크스페이스 선택',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '작업할 워크스페이스를 선택하거나 새로운 워크스페이스를 생성하세요',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _hintColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // --- "새 워크스페이스 생성" 버튼 ---
                // (★★ 수정: '!' 제거)
                if (!isUserAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32.0),
                    child: SizedBox(
                      height: 48, // 버튼 높이
                      child: ElevatedButton.icon(
                        // (★★ 수정: AppCore의 콜백을 직접 호출)
                        onPressed: onCreateWorkspace,
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        label: Text(
                          '새 워크스페이스 생성',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tossPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                      ),
                    ),
                  ),

                // --- 워크스페이스 카드 그리드 ---
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 한 줄에 3개
                    crossAxisSpacing: 24, // 가로 간격
                    mainAxisSpacing: 24, // 세로 간격
                    childAspectRatio: 1.25,
                  ),
                  // (★★ 수정: itemCount는 workspaces.length)
                  itemCount: workspaces.length,
                  itemBuilder: (context, index) {
                    // (★★ 수정: wsIndex -> index. 타입 변환 필요 없음)
                    final Workspace workspace = workspaces[index];
                    return _buildWorkspaceCard(context, workspace);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // (이하 헬퍼 함수들은 모두 정상. 기존과 동일)

  // 워크스페이스 카드 위젯 빌더
  Widget _buildWorkspaceCard(BuildContext context, Workspace workspace) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => onWorkspaceSelected(workspace.id, workspace.name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: _cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 및 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getWorkspaceIcon(workspace.name),
                  size: 36,
                  color: _tossPrimary,
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 워크스페이스 이름
            Text(
              workspace.name,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: _textColor,
                fontSize: 22,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 워크스페이스 타입
            Text(
              _getWorkspaceType(workspace.name),
              style: textTheme.bodyLarge?.copyWith(color: _hintColor, fontSize: 15),
            ),
            const SizedBox(height: 12),

            // 워크스페이스 설명
            Expanded(
              child: Text(
                workspace.description,
                style: textTheme.bodySmall?.copyWith(color: _hintColor, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),

            // 멤버 수, 생성일, 화살표
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: _hintColor),
                    const SizedBox(width: 4),
                    Text('${workspace.members.length}명', style: textTheme.bodySmall?.copyWith(color: _hintColor, fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: _hintColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(workspace.createdAt),
                      style: textTheme.bodySmall?.copyWith(color: _hintColor, fontSize: 13),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward, size: 20, color: _tossPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 워크스페이스 이름에 따른 아이콘 반환
  IconData _getWorkspaceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('default')) {
      return Icons.person_outline;
    } else if (lowerName.contains('development')) {
      return Icons.people_outline;
    } else if (lowerName.contains('production')) {
      return Icons.business_center_outlined;
    }
    return Icons.folder_open;
  }

  // 워크스페이스 이름에 따른 타입 반환
  String _getWorkspaceType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('default')) {
      return '개인 프로젝트를 위한 기본 워크스페이스';
    } else if (lowerName.contains('development')) {
      return '개발팀 협업을 위한 워크스페이스';
    } else if (lowerName.contains('production')) {
      return '운영 및 관리를 위한 워크스페이스';
    }
    return '일반 워크스페이스';
  }

  // 날짜 포맷팅
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}