import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/settings.dart';
import '../pages/profile.dart';
import '../l10n/app_localizations.dart';
import '../app_state.dart';
import '../models/user_data.dart';

class ProfileMenuButton extends StatelessWidget {
  final User currentUser;
  final UserData? userData;
  final VoidCallback onLogout;
  final VoidCallback onShowProfile;

  const ProfileMenuButton({
    Key? key,
    required this.currentUser,
    this.userData,
    required this.onLogout,
    required this.onShowProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final AppState appState = AppState.instance;

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'settings') {
          // (참고: SettingsPage도 이 방식으로 변경하는 것이 좋습니다)
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => SettingsPage(
                currentUser: currentUser,
                userData: userData,
                onShowProfile: onShowProfile,
              ),
              settings: RouteSettings(name: '/settings')
          ));
        } else if (value == 'logout') {
          // (수정) onLogout 콜백을 사용하도록 통일
          onLogout();
        } else if (value == 'mypage') {
          onShowProfile();
        }
        // (수정) 중복된 logout 핸들러 제거
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
            value: 'account',
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    userData?.displayName ?? currentUser.email ?? '이름 없음',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color)
                ),
                Text(
                    currentUser.email ?? '이메일 없음',
                    style: TextStyle(color: theme.hintColor, fontSize: 12)
                ),
              ],
            )
        ),
        if (userData?.role == 'admin')
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
          value: 'mypage', // (이 버튼을 누르면 ProfilePage로 이동)
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
        PopupMenuDivider(),

        // (다크 모드 스위치 - 기존과 동일)
        PopupMenuItem<String>(
          value: 'theme_switch',
          enabled: false,
          child: ValueListenableBuilder<ThemeMode>(
              valueListenable: appState.themeMode,
              builder: (context, currentMode, child) {
                final isDark = currentMode == ThemeMode.dark;
                return SwitchListTile(
                  title: Text(l10n.darkMode, style: theme.textTheme.bodyMedium),
                  value: isDark,
                  onChanged: (bool value) {
                    appState.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                  secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                );
              }
          ),
        ),

        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Text(l10n.logout, style: TextStyle(color: Colors.red[700])),
        ),
      ],
      // (아이콘 - 기존과 동일)
      icon: CircleAvatar(
        backgroundColor: theme.dividerColor.withOpacity(0.5),
        foregroundColor: theme.colorScheme.primary,
        radius: 16,
        child: Text(
          currentUser.email?[0].toUpperCase() ?? 'U',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}