// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Deplight';

  @override
  String get workspaceSelectTitle =>
      'Which workspace\nwould you like to go to?';

  @override
  String get apps => 'Apps';

  @override
  String get deployNewApp => 'Deploy New App';

  @override
  String get launchApp => 'Launch App';

  @override
  String get settings => 'Settings';

  @override
  String get workbenchTitle => 'Workbench:';

  @override
  String get loadingTitle => 'Preparing new deployment...';

  @override
  String get loadingMessage => 'Preparing a new pot...';

  @override
  String get tabConsole => 'Console';

  @override
  String get tabVitals => 'Vitals (Metrics)';

  @override
  String get tabAIGardener => 'AI Gardener';

  @override
  String get tabGlobalTraffic => 'Global Traffic';

  @override
  String get tabEnvironment => 'Environment';

  @override
  String get consoleHint => 'kubectl get pods (fake command...)';

  @override
  String get vitalsTitle => 'Real-time Plant Vitals (Prometheus)';

  @override
  String get vitalsCPU => 'Sunlight (CPU %)';

  @override
  String get vitalsMemory => 'Water (Memory MB)';

  @override
  String get statusTitle => 'Plant Status';

  @override
  String get rollbackNow => 'Immediate Rollback (to v1.1)';

  @override
  String get rollbackConfirmTitle => '🚨 Immediate Rollback';

  @override
  String get rollbackConfirmMessage =>
      'Are you sure you want to roll back to the previous version?';

  @override
  String get rollbackAction => 'Execute Rollback';

  @override
  String get cancel => 'Cancel';

  @override
  String get statusResources => 'Real-time Resource Usage';

  @override
  String get statusAITitle => '💡 AI Gardener\'s Analysis (Pest Insight)';

  @override
  String get trafficTitle => 'Global Traffic Hits (Live)';

  @override
  String get envTitle => 'Environment Variables';

  @override
  String get envSubtitle => 'Applied on app restart.';

  @override
  String get envAdd => 'Add Variable';

  @override
  String get envSaveAndRedeploy => 'Save and Redeploy';

  @override
  String get settingsGithub => 'GitHub Repository';

  @override
  String get settingsSecrets => 'Environment Variables (Secrets)';

  @override
  String get settingsSlack => 'Slack Notifications';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeCurrent => 'Current: System Default';

  @override
  String get profileTitle => 'Jaeseok Han';

  @override
  String get profileEmail => 'jaeseok.han@email.com';

  @override
  String get profileRole => 'Admin';

  @override
  String get myPage => 'Profile';

  @override
  String get security => 'Security';

  @override
  String get workspaceSettings => 'Workspace Settings';

  @override
  String get members => 'Members';

  @override
  String get billing => 'Billing';

  @override
  String get logout => 'Logout';

  @override
  String get deployNewSeed => 'Plant New Seed (Deploy)';

  @override
  String get retry => 'Catch Fly (Retry)';

  @override
  String get settingsLanguage => 'Language Settings';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get plantStatusSleeping => 'Sleeping';

  @override
  String get wakeUpTitle => 'This App is Sleeping 💤';

  @override
  String get wakeUpMessage =>
      'This app was moved to \'Hibernation\' mode to save costs due to 72 hours of inactivity.';

  @override
  String get wakeUpButton => 'Wake Up App';
}
