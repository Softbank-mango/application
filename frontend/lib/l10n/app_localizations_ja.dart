// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Deplight';

  @override
  String get workspaceSelectTitle => 'どのワークスペースに\n移動しますか？';

  @override
  String get apps => 'アプリ';

  @override
  String get deployNewApp => '新規アプリをデプロイ';

  @override
  String get launchApp => 'アプリを起動';

  @override
  String get settings => '設定';

  @override
  String get workbenchTitle => '作業台:';

  @override
  String get loadingTitle => '新規デプロイを準備中...';

  @override
  String get loadingMessage => '新しい鉢を準備しています...';

  @override
  String get tabConsole => 'コンソール';

  @override
  String get tabVitals => 'バイタル (メトリクス)';

  @override
  String get tabAIGardener => 'AIガーデナー';

  @override
  String get tabGlobalTraffic => 'グローバルトラフィック';

  @override
  String get tabEnvironment => '環境変数';

  @override
  String get consoleHint => 'kubectl get pods (ダミーコマンド...)';

  @override
  String get vitalsTitle => 'リアルタイム植物バイタル (Prometheus)';

  @override
  String get vitalsCPU => '日照量 (CPU %)';

  @override
  String get vitalsMemory => '水分 (Memory MB)';

  @override
  String get statusTitle => '植物の状態';

  @override
  String get rollbackNow => '即時ロールバック (v1.1へ)';

  @override
  String get rollbackConfirmTitle => '🚨 即時ロールバック';

  @override
  String get rollbackConfirmMessage => '本当に前のバージョンにロールバックしますか？';

  @override
  String get rollbackAction => 'ロールバック実行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get statusResources => 'リアルタイムリソース使用量';

  @override
  String get statusAITitle => '💡 AIガーデナーの分析 (害虫の原因)';

  @override
  String get trafficTitle => 'Global Traffic Hits (Live)';

  @override
  String get envTitle => '環境変数';

  @override
  String get envSubtitle => 'アプリの再起動時に適用されます。';

  @override
  String get envAdd => '変数を追加';

  @override
  String get envSaveAndRedeploy => '保存して再デプロイ';

  @override
  String get settingsGithub => 'GitHubリポジトリ連携';

  @override
  String get settingsSecrets => '環境変数 (Secrets)';

  @override
  String get settingsSlack => 'Slack通知設定';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeCurrent => '現在: システム設定';

  @override
  String get profileTitle => 'Jaeseok Han';

  @override
  String get profileEmail => 'jaeseok.han@email.com';

  @override
  String get profileRole => '管理者';

  @override
  String get myPage => 'プロフィール';

  @override
  String get security => 'セキュリティ';

  @override
  String get workspaceSettings => 'ワークスペース設定';

  @override
  String get members => 'メンバー';

  @override
  String get billing => '決済';

  @override
  String get logout => 'ログアウト';

  @override
  String get deployNewSeed => '新しい種を植える (Deploy)';

  @override
  String get retry => 'ハエを捕まえる (Retry)';

  @override
  String get settingsLanguage => '言語設定';

  @override
  String get theme => 'テーマ';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get plantStatusSleeping => '冬眠中';

  @override
  String get wakeUpTitle => 'アプリは冬眠中です 💤';

  @override
  String get wakeUpMessage => '72時間トラフィックがなかったため、コスト削減のために「冬眠」モードに移行しました。';

  @override
  String get wakeUpButton => 'アプリを起こす (Wake Up)';
}
