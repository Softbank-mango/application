import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp 때문에 필요
import '../models/user_data.dart';
import '../models/workspace.dart';
import '../widgets/profile_menu.dart'; // (로그아웃 버튼을 ProfileMenuButton으로 대체 예정)

class WorkspaceSelectionPage extends StatelessWidget {
  final Function(String, String) onWorkspaceSelected;
  final Function(String, String) onCreateWorkspace; // 이름, 설명 모두 받도록 변경
  final Function() onLogout; // 로그아웃 함수 추가
  final User currentUser;
  final Map<String, dynamic>? userData;
  final List<dynamic> workspaces; // AppCore로부터 받은 워크스페이스 목록

  const WorkspaceSelectionPage({
    Key? key,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
    required this.onLogout, // 로그아웃 함수 필수
    required this.currentUser,
    this.userData,
    required this.workspaces,
  }) : super(key: key);

  // 색상 정의 (이미지 분석 기반)
  final Color _tossPrimary = const Color(0xFF678AFB);
  final Color _gradientStart = const Color(0xFFEFF6FF);
  final Color _gradientEnd = const Color(0xFFFAF5FF);
  final Color _textColor = const Color(0xFF333333);
  final Color _hintColor = const Color(0xFF999999);
  final Color _cardBackgroundColor = Colors.white;

  // 새 워크스페이스 생성 다이얼로그 (이미지 스타일에 맞게 업데이트)
  void _showCreateWorkspaceDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController(); // 설명 필드 추가
    final _formKey = GlobalKey<FormState>(); // 폼 유효성 검사

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0), // 패딩 조정
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
                  hintText: 'My Project Workspace',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _tossPrimary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '워크스페이스 이름을 입력해주세요.';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: '설명',
                  hintText: '이 워크스페이스는 어떤 용도로 사용되나요?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _tossPrimary, width: 2),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '워크스페이스 설명을 입력해주세요.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('취소', style: TextStyle(color: _hintColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                onCreateWorkspace(nameController.text, descriptionController.text);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _tossPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUserAdmin = userData?['role'] == 'admin'; // 사용자 역할 확인

    return Scaffold(
      body: Container(
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
                  // --- 상단 내비게이션 (로고 + 로그아웃) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 로고 (Deplight)
                      Row(
                        children: [
                          Image.asset('assets/deplight_logo_52.png', height: 40, width: 40, fit: BoxFit.contain),
                          const SizedBox(width: 8), // 이미지 간격 조정
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
                      // 로그아웃 버튼 (이미지와 동일한 스타일)
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
                          overlayColor: _tossPrimary.withOpacity(0.1), // 호버 효과
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60), // 상단 내비게이션과 제목 사이 간격

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

                  // --- "새 워크스페이스 생성" 버튼 (이미지 위치에 정확히 배치) ---
                  // 이미지상에서는 그리드 상단에 배치되어 있습니다.
                  if (isUserAdmin) // 관리자에게만 버튼 표시
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: SizedBox(
                        height: 48, // 버튼 높이
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateWorkspaceDialog(context),
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
                      childAspectRatio: 1.25, // 카드 종횡비 (이미지에 맞춤)
                    ),
                    itemCount: workspaces.length, // '생성' 버튼을 그리드에서 제외했으므로 실제 워크스페이스 수만 사용
                    itemBuilder: (context, index) {
                      final wsData = workspaces[index];

                      // Firestore Map을 Workspace 모델 객체로 변환
                      final workspace = Workspace(
                        id: wsData['id'],
                        name: wsData['name'],
                        description: wsData['description'] ?? '이 워크스페이스에 대한 설명이 없습니다.',
                        ownerUid: wsData['ownerUid'],
                        members: List<String>.from(wsData['members'] ?? []),
                        createdAt: wsData['createdAt'] ?? Timestamp.now(),
                      );
                      return _buildWorkspaceCard(context, workspace);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 워크스페이스 카드 위젯 빌더 (이미지 레이아웃에 완벽 일치)
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
            // 아이콘 및 상태 (이미지 기반)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _getWorkspaceIcon(workspace.name), // 이름 기반 아이콘
                  size: 36,
                  color: _tossPrimary,
                ),
                // 더미 상태 점 (실제 상태에 따라 색상 변경 가능)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent, // (활성 상태 예시)
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
                fontSize: 22, // 이미지와 유사하게 조정
                height: 1.2, // 줄 높이
              ),
              maxLines: 1, // 한 줄로 제한
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 워크스페이스 타입 (이미지에서 '개인', '팀', '기업' 부분)
            Text(
              _getWorkspaceType(workspace.name),
              style: textTheme.bodyLarge?.copyWith(color: _hintColor, fontSize: 15), // 이미지와 유사하게 조정
            ),
            const SizedBox(height: 12),

            // 워크스페이스 설명
            Expanded( // 설명이 길 경우를 대비하여 Expanded 사용
              child: Text(
                workspace.description,
                style: textTheme.bodySmall?.copyWith(color: _hintColor, fontSize: 13), // 이미지와 유사하게 조정
                maxLines: 2, // 최대 2줄
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),

            // 멤버 수, 생성일, 화살표
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, // 세로 중앙 정렬
              children: [
                // 멤버 수
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: _hintColor),
                    const SizedBox(width: 4),
                    Text('${workspace.members.length}명', style: textTheme.bodySmall?.copyWith(color: _hintColor, fontSize: 13)),
                  ],
                ),
                // 생성일
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
                // 화살표 아이콘
                Icon(Icons.arrow_forward, size: 20, color: _tossPrimary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 워크스페이스 이름에 따른 아이콘 반환 (이미지 기반)
  IconData _getWorkspaceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('default')) {
      return Icons.person_outline;
    } else if (lowerName.contains('development')) {
      return Icons.people_outline;
    } else if (lowerName.contains('production')) {
      return Icons.business_center_outlined;
    }
    return Icons.folder_open; // 기본 아이콘
  }

  // 워크스페이스 이름에 따른 타입 반환 (이미지 기반)
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