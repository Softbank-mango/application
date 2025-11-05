// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Deplight';

  @override
  String get workspaceSelectTitle => '어떤 워크스페이스로\n이동할까요?';

  @override
  String get apps => '앱';

  @override
  String get deployNewApp => '새 앱 배포하기';

  @override
  String get launchApp => '앱 시작하기';

  @override
  String get settings => '설정';

  @override
  String get workbenchTitle => '작업대:';

  @override
  String get loadingTitle => '새 배포 준비 중...';

  @override
  String get loadingMessage => '새 화분을 준비하고 있습니다...';

  @override
  String get tabConsole => '콘솔';

  @override
  String get tabVitals => '활력 징후 (Vitals)';

  @override
  String get tabAIGardener => 'AI 가드너';

  @override
  String get tabGlobalTraffic => '글로벌 트래픽';

  @override
  String get tabEnvironment => '환경 변수';

  @override
  String get consoleHint => 'kubectl get pods (가짜 명령어 입력...)';

  @override
  String get vitalsTitle => '실시간 식물 활력 (Prometheus)';

  @override
  String get vitalsCPU => '일조량 (CPU %)';

  @override
  String get vitalsMemory => '수분 (Memory MB)';

  @override
  String get statusTitle => '식물 상태';

  @override
  String get rollbackNow => '즉시 롤백 (v1.1로 되돌리기)';

  @override
  String get rollbackConfirmTitle => '🚨 즉시 롤백';

  @override
  String get rollbackConfirmMessage => '정말로 이전 버전으로 롤백하시겠습니까?';

  @override
  String get rollbackAction => '롤백 실행';

  @override
  String get cancel => '취소';

  @override
  String get statusResources => '실시간 자원 사용량';

  @override
  String get statusAITitle => '💡 AI Gardener의 분석 (파리 원인)';

  @override
  String get trafficTitle => 'Global Traffic Hits (Live)';

  @override
  String get envTitle => '환경 변수 (Environment)';

  @override
  String get envSubtitle => '앱 재시작 시 적용됩니다.';

  @override
  String get envAdd => '변수 추가';

  @override
  String get envSaveAndRedeploy => '저장 및 재배포';

  @override
  String get settingsGithub => 'GitHub 리포지토리 연동';

  @override
  String get settingsSecrets => '환경 변수 (Secrets)';

  @override
  String get settingsSlack => 'Slack 알림 설정';

  @override
  String get settingsTheme => '테마 변경';

  @override
  String get settingsThemeCurrent => '현재: 시스템 설정';

  @override
  String get profileTitle => '재석 한';

  @override
  String get profileEmail => 'jaeseok.han@email.com';

  @override
  String get profileRole => 'Admin';

  @override
  String get myPage => '프로필';

  @override
  String get security => '보안';

  @override
  String get workspaceSettings => '워크스페이스 설정';

  @override
  String get members => '멤버';

  @override
  String get billing => '결제';

  @override
  String get logout => '로그아웃';

  @override
  String get deployNewSeed => '새 씨앗 심기 (Deploy)';

  @override
  String get retry => '파리 잡기 (Retry)';

  @override
  String get settingsLanguage => '언어 설정';

  @override
  String get theme => '테마';

  @override
  String get darkMode => '다크 모드';
}
