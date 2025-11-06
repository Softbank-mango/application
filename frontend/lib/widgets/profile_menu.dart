import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/settings.dart';
import '../l10n/app_localizations.dart';
import '../app_state.dart'; // (신규) 글로벌 상태 임포트

// --- (9) 프로필 메뉴 버튼 위젯 ---
class ProfileMenuButton extends StatelessWidget {
  final User currentUser;
  final Map<String, dynamic>? userData;

  const ProfileMenuButton({
    Key? key,
    required this.currentUser, // (★★★★★)
    this.userData,             // (★★★★★)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // (신규) 글로벌 상태 인스턴스
    final AppState appState = AppState.instance;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'settings') {
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => SettingsPage(
                currentUser: currentUser,
                userData: userData,
              ),
              settings: RouteSettings(name: '/settings')
          ));
        } else if (value == 'logout') {
          // (★★★★★ 신규 ★★★★★: 로그아웃 로직 추가)
          FirebaseAuth.instance.signOut();
        } else if (value == 'mypage') {
          // ... (이전과 동일)
        } else if (value == 'logout') {
          FirebaseAuth.instance.signOut();
        }
        // (신규) 다크 모드 스위치 자체는 onSelected를 호출하지 않음
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'account',
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Firestore에 저장된 'displayName'을 사용하고,
                  // 없으면 Auth의 이메일을, 그것도 없으면 '이름 없음'을 표시
                    userData?['displayName'] ?? currentUser.email ?? '이름 없음',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)
                ),
                // Auth의 'email' 사용
                Text(
                    currentUser.email ?? '이메일 없음',
                    style: TextStyle(color: theme.hintColor, fontSize: 12)
                ),
              ],
            )
        ),
        PopupMenuItem<String>(
            value: 'admin',
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.profileTitle),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                  child: Text(l10n.profileRole, style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            )
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'mypage',
          child: Text(l10n.myPage),
        ),
        PopupMenuItem<String>(
          value: 'security',
          child: Text(l10n.security),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'settings',
          child: Text(l10n.workspaceSettings),
        ),
        // ... (멤버, 결제 메뉴는 l10n 적용...)
        PopupMenuDivider(),

        // --- (신규) 다크 모드 스위치 ---
        PopupMenuItem<String>(
          value: 'theme_switch',
          enabled: false, // 항목 자체는 클릭 방지
          child: ValueListenableBuilder<ThemeMode>(
              valueListenable: appState.themeMode,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return SwitchListTile(
                  title: Text(l10n.darkMode, style: theme.textTheme.bodyMedium),
                  value: isDark,
                  onChanged: (bool value) {
                    // 글로벌 상태 변경
                    appState.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                  secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                );
              }
          ),
        ),
        // -----------------------------

        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Text(l10n.logout, style: TextStyle(color: Colors.red[700])),
        ),
      ],
      icon: CircleAvatar(
        backgroundColor: theme.dividerColor.withOpacity(0.5),
        foregroundColor: theme.colorScheme.primary,
        radius: 16,
        child: Text(
          currentUser.email?[0].toUpperCase() ?? 'U', // 이메일 첫 글자
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}