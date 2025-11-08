import 'package:flutter/material.dart';
import '../models/workspace.dart'; // (Workspace 모델 임포트)

class WorkspaceSwitcher extends StatelessWidget {
  final List<Workspace> workspaces;
  final String? currentWorkspaceId;
  final String currentWorkspaceName;
  final Function(String, String) onWorkspaceSelected;
  final VoidCallback onCreateWorkspace;

  const WorkspaceSwitcher({
    Key? key,
    required this.workspaces,
    this.currentWorkspaceId,
    required this.currentWorkspaceName,
    required this.onWorkspaceSelected,
    required this.onCreateWorkspace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // --- (신규) 이미지와 100% 일치하는 색상 정의 ---
    const Color iconColor = Color(0xFF6B7280); // 버튼 아이콘/화살표
    const Color textColor = Color(0xFF111827); // 버튼 텍스트
    const Color selectedTextColor = Color(0xFF2563EB); // 메뉴 - 선택된 텍스트/아이콘
    const Color selectedBgColor = Color(0xFFEFF6FF); // 메뉴 - 선택된 배경
    const Color menuIconColor = Color(0xFF4B5563); // 메뉴 - 기본 아이콘

    // --- (신규) 팝업 메뉴를 여는 버튼 (Child) ---
    // 기존의 파란 배경 컨테이너 대신, 이미지와 동일한 UI로 변경
    Widget triggerButton = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      // (참고) TopBar와 배경색을 맞추기 위해 transparent로 설정
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // (신규) 이미지에 있는 건물 아이콘
          const Icon(Icons.corporate_fare_outlined, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(
            // 워크스페이스가 선택되었는지 확인
            currentWorkspaceId != null ? currentWorkspaceName : "워크스페이스 선택",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor, // (수정) theme.colorScheme.primary -> textColor
            ),
          ),
          const SizedBox(width: 4),
          // (수정) 아이콘 및 색상 변경
          const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: iconColor),
        ],
      ),
    );

    // --- (신규) PopupMenuButton으로 감싸기 ---
    return PopupMenuButton<String>(
      tooltip: "워크스페이스 전환",
      // (신규) 메뉴가 버튼 바로 아래(수직 50px)에 뜨도록 오프셋 조정
      offset: const Offset(0, 50),
      // (신규) 모서리 둥글게 (이미지 기준 12px)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      // (신규) 그림자 (elevation)
      elevation: 8,
      // (신규) 메뉴 배경색
      color: Colors.white,
      // (신규) 메뉴가 차지할 수 있는 너비 (이미지 기준)
      constraints: const BoxConstraints(minWidth: 280),

      onSelected: (String value) {
        if (value == '__CREATE_NEW__') {
          onCreateWorkspace();
        } else {
          final ws = workspaces.firstWhere((w) => w.id == value);
          onWorkspaceSelected(ws.id, ws.name);
        }
      },

      itemBuilder: (BuildContext context) {
        List<PopupMenuEntry<String>> items = [];

        // 1. 워크스페이스 목록
        for (final ws in workspaces) { // (ws는 이제 Workspace 객체)
          final bool isSelected = ws.id == currentWorkspaceId;

          items.add(
            PopupMenuItem<String>(
              value: ws.id,
              // (수정) 배경색을 꽉 채우기 위해 기본 패딩 제거
              padding: EdgeInsets.zero,
              child: Container(
                // (수정) 선택 여부에 따라 배경색 변경
                color: isSelected ? selectedBgColor : Colors.white,
                // (수정) 패딩 수동 적용
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.corporate_fare_outlined, // (수정) 아이콘 통일
                      size: 20,
                      // (수정) 선택 여부에 따라 아이콘 색상 변경
                      color: isSelected ? selectedTextColor : menuIconColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ws.name,
                      style: TextStyle(
                        // (수정) 선택 여부에 따라 텍스트 스타일 변경
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? selectedTextColor : textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 2. 구분선
        // (수정) 구분선 위아래로 꽉 차도록 높이 1로 설정
        items.add(const PopupMenuDivider(height: 1.0));

        // 3. 새 워크스페이스 생성 버튼
        items.add(
          PopupMenuItem<String>(
            value: '__CREATE_NEW__',
            padding: EdgeInsets.zero, // (수정)
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.add, size: 20, color: menuIconColor), // (수정)
                  const SizedBox(width: 12),
                  const Text(
                    "새 워크스페이스 생성", // (.arb에 없으므로 하드코딩)
                    style: TextStyle(color: textColor, fontSize: 16), // (수정)
                  ),
                ],
              ),
            ),
          ),
        );

        return items;
      },

      child: triggerButton, // 위에서 정의한 버튼 위젯
    );
  }
}