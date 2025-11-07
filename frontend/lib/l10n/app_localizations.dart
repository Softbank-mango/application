import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko')
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'Deplight'**
  String get appName;

  /// No description provided for @workspaceSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 워크스페이스로\n이동할까요?'**
  String get workspaceSelectTitle;

  /// No description provided for @apps.
  ///
  /// In ko, this message translates to:
  /// **'앱'**
  String get apps;

  /// No description provided for @deployNewApp.
  ///
  /// In ko, this message translates to:
  /// **'새 앱 배포하기'**
  String get deployNewApp;

  /// No description provided for @launchApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 시작하기'**
  String get launchApp;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @workbenchTitle.
  ///
  /// In ko, this message translates to:
  /// **'작업대:'**
  String get workbenchTitle;

  /// No description provided for @loadingTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 배포 준비 중...'**
  String get loadingTitle;

  /// No description provided for @loadingMessage.
  ///
  /// In ko, this message translates to:
  /// **'새 화분을 준비하고 있습니다...'**
  String get loadingMessage;

  /// No description provided for @tabConsole.
  ///
  /// In ko, this message translates to:
  /// **'콘솔'**
  String get tabConsole;

  /// No description provided for @tabVitals.
  ///
  /// In ko, this message translates to:
  /// **'활력 징후 (Vitals)'**
  String get tabVitals;

  /// No description provided for @tabAIGardener.
  ///
  /// In ko, this message translates to:
  /// **'AI 가드너'**
  String get tabAIGardener;

  /// No description provided for @tabGlobalTraffic.
  ///
  /// In ko, this message translates to:
  /// **'글로벌 트래픽'**
  String get tabGlobalTraffic;

  /// No description provided for @tabEnvironment.
  ///
  /// In ko, this message translates to:
  /// **'환경 변수'**
  String get tabEnvironment;

  /// No description provided for @consoleHint.
  ///
  /// In ko, this message translates to:
  /// **'kubectl get pods (가짜 명령어 입력...)'**
  String get consoleHint;

  /// No description provided for @vitalsTitle.
  ///
  /// In ko, this message translates to:
  /// **'실시간 식물 활력 (Prometheus)'**
  String get vitalsTitle;

  /// No description provided for @vitalsCPU.
  ///
  /// In ko, this message translates to:
  /// **'일조량 (CPU %)'**
  String get vitalsCPU;

  /// No description provided for @vitalsMemory.
  ///
  /// In ko, this message translates to:
  /// **'수분 (Memory MB)'**
  String get vitalsMemory;

  /// No description provided for @statusTitle.
  ///
  /// In ko, this message translates to:
  /// **'식물 상태'**
  String get statusTitle;

  /// No description provided for @rollbackNow.
  ///
  /// In ko, this message translates to:
  /// **'즉시 롤백 (v1.1로 되돌리기)'**
  String get rollbackNow;

  /// No description provided for @rollbackConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'🚨 즉시 롤백'**
  String get rollbackConfirmTitle;

  /// No description provided for @rollbackConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'정말로 이전 버전으로 롤백하시겠습니까?'**
  String get rollbackConfirmMessage;

  /// No description provided for @rollbackAction.
  ///
  /// In ko, this message translates to:
  /// **'롤백 실행'**
  String get rollbackAction;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @statusResources.
  ///
  /// In ko, this message translates to:
  /// **'실시간 자원 사용량'**
  String get statusResources;

  /// No description provided for @statusAITitle.
  ///
  /// In ko, this message translates to:
  /// **'💡 AI Gardener의 분석 (파리 원인)'**
  String get statusAITitle;

  /// No description provided for @trafficTitle.
  ///
  /// In ko, this message translates to:
  /// **'Global Traffic Hits (Live)'**
  String get trafficTitle;

  /// No description provided for @envTitle.
  ///
  /// In ko, this message translates to:
  /// **'환경 변수 (Environment)'**
  String get envTitle;

  /// No description provided for @envSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱 재시작 시 적용됩니다.'**
  String get envSubtitle;

  /// No description provided for @envAdd.
  ///
  /// In ko, this message translates to:
  /// **'변수 추가'**
  String get envAdd;

  /// No description provided for @envSaveAndRedeploy.
  ///
  /// In ko, this message translates to:
  /// **'저장 및 재배포'**
  String get envSaveAndRedeploy;

  /// No description provided for @settingsGithub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 리포지토리 연동'**
  String get settingsGithub;

  /// No description provided for @settingsSecrets.
  ///
  /// In ko, this message translates to:
  /// **'환경 변수 (Secrets)'**
  String get settingsSecrets;

  /// No description provided for @settingsSlack.
  ///
  /// In ko, this message translates to:
  /// **'Slack 알림 설정'**
  String get settingsSlack;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마 변경'**
  String get settingsTheme;

  /// No description provided for @settingsThemeCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재: 시스템 설정'**
  String get settingsThemeCurrent;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'재석 한'**
  String get profileTitle;

  /// No description provided for @profileEmail.
  ///
  /// In ko, this message translates to:
  /// **'jaeseok.han@email.com'**
  String get profileEmail;

  /// No description provided for @profileRole.
  ///
  /// In ko, this message translates to:
  /// **'Admin'**
  String get profileRole;

  /// No description provided for @myPage.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get myPage;

  /// No description provided for @security.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get security;

  /// No description provided for @workspaceSettings.
  ///
  /// In ko, this message translates to:
  /// **'워크스페이스 설정'**
  String get workspaceSettings;

  /// No description provided for @members.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get members;

  /// No description provided for @billing.
  ///
  /// In ko, this message translates to:
  /// **'결제'**
  String get billing;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deployNewSeed.
  ///
  /// In ko, this message translates to:
  /// **'새 씨앗 심기 (Deploy)'**
  String get deployNewSeed;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'파리 잡기 (Retry)'**
  String get retry;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get settingsLanguage;

  /// No description provided for @theme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkMode;

  /// No description provided for @plantStatusSleeping.
  ///
  /// In ko, this message translates to:
  /// **'겨울잠'**
  String get plantStatusSleeping;

  /// No description provided for @wakeUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'앱이 \'겨울잠\' 상태입니다 💤'**
  String get wakeUpTitle;

  /// No description provided for @wakeUpMessage.
  ///
  /// In ko, this message translates to:
  /// **'앱이 72시간 동안 트래픽이 없어 비용 절약을 위해 \'겨울잠\' 모드로 전환되었습니다.'**
  String get wakeUpMessage;

  /// No description provided for @wakeUpButton.
  ///
  /// In ko, this message translates to:
  /// **'앱 깨우기 (Wake Up)'**
  String get wakeUpButton;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'ko': return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
