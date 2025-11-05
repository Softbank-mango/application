import 'package:flutter/material.dart';
import '../widgets/profile_menu.dart';
import '../l10n/app_localizations.dart'; // (신규)

// --- (3) "워크스페이스 선택" 페이지 (1.png) ---
class WorkspaceSelectionPage extends StatelessWidget {
  final Function(String, String) onWorkspaceSelected;

  const WorkspaceSelectionPage({
    Key? key,
    required this.onWorkspaceSelected,
  }) : super(key: key);

  // (더미 데이터는 l10n과 무관하므로 유지)
  final List<Map<String, String>> hardcodedWorkspaces = const [
// ... (이전 코드와 동일) ...
    { 'id': 'ws_id_lguplus', 'name': 'LG Uplus', 'icon': 'L' },
    { 'id': 'ws_id_unicef', 'name': '유니세프', 'icon': '유' },
    { 'id': 'ws_id_cjenm', 'name': 'CJ ENM', 'icon': 'C' },
    { 'id': 'ws_id_letour', 'name': '⭐ Letour_내부용', 'icon': '⭐' },
    { 'id': 'ws_id_samsung', 'name': '삼성전자 글로벌마케팅', 'icon': 'S' },
    { 'id': 'ws_id_library', 'name': '국립중앙도서관', 'icon': '국' },
  ];


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!; // (신규) l10n 객체

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)), // (수정)
        actions: [ ProfileMenuButton() ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 32),
                Text(l10n.workspaceSelectTitle, // (수정)
                  style: textTheme.headlineLarge?.copyWith(
                    color: textTheme.displayLarge?.color,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 32),

                Expanded(
                  child: ListView.builder(
                    itemCount: hardcodedWorkspaces.length,
                    itemBuilder: (context, index) {
// ... (이하 카드 UI 로직은 이전과 동일) ...
                      final ws = hardcodedWorkspaces[index];
                      String wsName = ws['name']!;
                      String wsId = ws['id']!;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onWorkspaceSelected(wsId, wsName),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                                    child: Text(
                                        ws['icon'] ?? wsName[0],
                                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    wsName,
                                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}