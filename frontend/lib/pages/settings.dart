import 'package:flutter/material.dart';
import '../widgets/profile_menu.dart';
import '../l10n/app_localizations.dart';
import 'language_selection.dart';
import '../app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_data.dart';

// --- (7) "설정" 페이지 (Placeholder) ---
class SettingsPage extends StatelessWidget {
  final User currentUser;
  final UserData? userData;
  final VoidCallback onShowProfile;

  const SettingsPage({
    Key? key,
    required this.currentUser,
    this.userData,
    required this.onShowProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = AppState.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [
          ProfileMenuButton(
            currentUser: currentUser,
            userData: userData,
            onLogout: () => FirebaseAuth.instance.signOut(),
            onShowProfile: onShowProfile,
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.link),
            title: Text(l10n.settingsGithub),
            subtitle: Text('연결 안 됨'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.vpn_key),
            title: Text(l10n.settingsSecrets),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text(l10n.settingsSlack),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: Text(l10n.settingsTheme),
            // (신규) ValueListenableBuilder로 실시간 테마 모드 표시
            subtitle: ValueListenableBuilder<ThemeMode>(
                valueListenable: appState.themeMode,
                builder: (context, mode, child) {
                  String modeText = "시스템 설정";
                  if (mode == ThemeMode.light) modeText = "라이트 모드";
                  if (mode == ThemeMode.dark) modeText = "다크 모드";
                  return Text("현재: $modeText");
                }
            ),
            onTap: () {
              // (신규) 프로필 버튼의 스위치를 사용하도록 유도
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('테마 변경은 우측 상단 프로필 메뉴를 이용해주세요.'))
              );
            },
          ),
          // --- (신규) 언어 설정 메뉴 ---
          ListTile(
            leading: Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            // (신규) ValueListenableBuilder로 실시간 언어 표시
            subtitle: ValueListenableBuilder<Locale>(
                valueListenable: appState.locale,
                builder: (context, locale, child) {
                  String langText = "한국어";
                  if (locale.languageCode == 'en') langText = "English";
                  if (locale.languageCode == 'ja') langText = "日本語";
                  return Text("현재: $langText");
                }
            ),
            onTap: () {
              // (신규) 언어 선택 페이지로 이동
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => LanguageSelectionPage()
              ));
            },
          ),
          // ----------------------------
        ],
      ),
    );
  }
}