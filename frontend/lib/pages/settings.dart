import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  // (★★★★★) app_core의 body를 교체하기 위한 콜백
  // 이미지의 "프로필로 돌아가기" 버튼에 연결됩니다.
  final VoidCallback onGoBackToProfile;

  const SettingsPage({
    Key? key,
    required this.onGoBackToProfile,
  }) : super(key: key);

  // --- 이미지 기준 색상 정의 ---
  static const Color _backgroundColor = Color(0xFFF9FAFB); // 페이지 배경
  static const Color _cardColor = Colors.white;
  static const Color _textColor = Color(0xFF111827); // (진한 텍스트)
  static const Color _subTextColor = Color(0xFF6B7280); // (연한 텍스트)
  static const Color _borderColor = Color(0xFFE5E7EB); // (구분선, 테두리)
  static const Color _dangerColor = Color(0xFFEF4444); // (삭제 버튼)
  static const Color _primaryColor = Color(0xFF678AFB); // (앱 기본 파란색)
  static const Color _successColor = Color(0xFF10B981); // (연결됨)
  static const Color _avatarBgColor = Color(0xFFE0E7FF); // (아바타 배경)

  @override
  Widget build(BuildContext context) {
    // TopBar가 app_core에 있으므로 이 페이지는 Scaffold가 없습니다.
    return Container(
      color: _backgroundColor, // 1. 전체 배경색 적용
      child: SingleChildScrollView( // 2. 세로 오버플로우 시 스크롤
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200), // 최대 너비
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. 페이지 헤더 ---
                _buildHeader(context),
                const SizedBox(height: 24),
                // --- 2. 메인 컨텐츠 (2단 컬럼) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 2-1. 왼쪽 컬럼 ---
                    Expanded(
                      flex: 6, // (비율 조절)
                      child: _buildLeftColumn(context),
                    ),
                    const SizedBox(width: 24),
                    // --- 2-2. 오른쪽 컬럼 ---
                    Expanded(
                      flex: 4, // (비율 조절)
                      child: _buildRightColumn(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. 페이지 헤더 (설정 + 돌아가기) ---
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "설정",
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
            ),
            const SizedBox(height: 4),
            Text(
              "시스템 설정과 연동 서비스를 관리하세요",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: _subTextColor),
            ),
          ],
        ),
        // (★★★★★) 이미지와 동일하게 "프로필로 돌아가기" 버튼
        TextButton.icon(
          onPressed: onGoBackToProfile, // app_core의 콜백 호출
          icon: const Icon(Icons.arrow_back, size: 16, color: _primaryColor),
          label: const Text("프로필로 돌아가기"),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
        ),
      ],
    );
  }

  // --- 2-1. 왼쪽 컬럼 빌더 ---
  Widget _buildLeftColumn(BuildContext context) {
    return Column(
      children: [
        _buildGithubCard(context),
        const SizedBox(height: 24),
        _buildSecretsCard(context),
        const SizedBox(height: 24),
        _buildThemeCard(context),
      ],
    );
  }

  // --- 2-2. 오른쪽 컬럼 빌더 ---
  Widget _buildRightColumn(BuildContext context) {
    return Column(
      children: [
        _buildSlackCard(context),
        const SizedBox(height: 24),
        _buildLanguageCard(context),
      ],
    );
  }

  // --- 카드 공통 스타일 헬퍼 ---
  Widget _buildBaseCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  // --- 카드 헤더 헬퍼 ---
  Widget _buildCardHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold, color: _textColor),
    );
  }

  // --- GitHub 연결 카드 ---
  Widget _buildGithubCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, "GitHub 연결"),
          const SizedBox(height: 4),
          Text(
            "리포지토리 배포를 위한 GitHub 계정 연결",
            style: const TextStyle(color: _subTextColor),
          ),
          const SizedBox(height: 16),
          // 연결된 계정 정보
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarBgColor, // (ProfilePage와 동일)
                  child: const Text("김",
                      style: TextStyle(color: _primaryColor, fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("kimdev123",
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text("kim@company.com",
                        style: TextStyle(color: _subTextColor, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: _successColor),
                      SizedBox(width: 4),
                      Text("연결됨",
                          style: TextStyle(
                              color: _successColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 버튼
          Row(
            children: [
              OutlinedButton(
                onPressed: () {},
                child: Text("권한 재설정", style: TextStyle(color: _textColor)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _borderColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {},
                child: Text("연결 해제", style: TextStyle(color: _dangerColor)),
                style: TextButton.styleFrom(foregroundColor: _dangerColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Slack 알림 카드 ---
  Widget _buildSlackCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, "Slack 알림"),
          const SizedBox(height: 4),
          Text(
            "배포 상태를 Slack으로 알림 받기",
            style: const TextStyle(color: _subTextColor),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  "Slack 워크스페이스가 연결되지 않았습니다",
                  style: TextStyle(color: _subTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.link, size: 18),
                  label: Text("Slack 연결하기"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Secrets 관리 카드 ---
  Widget _buildSecretsCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(context, "Secrets 관리"),
                  const SizedBox(height: 4),
                  Text(
                    "환경 변수와 비밀 키를 안전하게 관리하세요",
                    style: const TextStyle(color: _subTextColor),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 18),
                label: Text("새 Secret 추가"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSecretRow("DATABASE_URL", "2024-01-15"),
          _buildSecretRow("API_SECRET_KEY", "2024-01-10"),
          _buildSecretRow("WEBHOOK_SECRET", "2024-01-08"),
        ],
      ),
    );
  }

  // "Secrets 관리" 헬퍼 (Secret Row)
  Widget _buildSecretRow(String key, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(Icons.key_outlined, color: _subTextColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(key,
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontFamily: 'monospace')),
              Text("마지막 업데이트: $date",
                  style: TextStyle(color: _subTextColor, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text("••••••••••••••••",
              style: TextStyle(color: _subTextColor, fontFamily: 'monospace')),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: _subTextColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: _dangerColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // --- 테마 설정 카드 ---
  Widget _buildThemeCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, "테마 설정"),
          const SizedBox(height: 4),
          Text(
            "인터페이스 테마를 선택하세요",
            style: const TextStyle(color: _subTextColor),
          ),
          const SizedBox(height: 16),
          _buildThemeOption(context, "라이트 모드", "밝은 테마",
              Icons.light_mode_outlined, true),
          const SizedBox(height: 8),
          _buildThemeOption(context, "다크 모드", "어두운 테마",
              Icons.dark_mode_outlined, false),
          const SizedBox(height: 8),
          _buildThemeOption(
              context, "시스템 설정", "시스템 테마 따라가기", Icons.settings_system_daydream, false),
        ],
      ),
    );
  }

  // "테마 설정" 헬퍼 (옵션)
  Widget _buildThemeOption(
      BuildContext context, String title, String subtitle, IconData icon, bool selected) {
    return InkWell(
      onTap: () {
        // (app_state.dart의 테마 변경 로직 호출)
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? _primaryColor : _borderColor,
              width: selected ? 2 : 1),
          color: selected ? _primaryColor.withOpacity(0.05) : _cardColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _primaryColor : _subTextColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: selected ? _primaryColor : _textColor)),
                Text(subtitle,
                    style: TextStyle(
                        color: selected ? _primaryColor : _subTextColor,
                        fontSize: 12)),
              ],
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle, color: _primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 언어 설정 카드 ---
  Widget _buildLanguageCard(BuildContext context) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context, "언어 설정"),
          const SizedBox(height: 4),
          Text(
            "인터페이스 언어를 변경하세요",
            style: const TextStyle(color: _subTextColor),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.language, color: _subTextColor),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("현재 언어",
                          style: TextStyle(color: _subTextColor, fontSize: 12)),
                      Text("한국어", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: _subTextColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _primaryColor, size: 18),
                const SizedBox(width: 10),
                Text(
                  "언어를 변경하면 페이지가 새로고침됩니다.",
                  style: TextStyle(color: _primaryColor, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}