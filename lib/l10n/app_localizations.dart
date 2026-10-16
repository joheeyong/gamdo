import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skip;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @history.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @noAnalysisYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 분석한 사진이 없습니다'**
  String get noAnalysisYet;

  /// No description provided for @analyzing.
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get analyzing;

  /// No description provided for @colorAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'색감 분석'**
  String get colorAnalysis;

  /// No description provided for @dominantColors.
  ///
  /// In ko, this message translates to:
  /// **'대표 색상'**
  String get dominantColors;

  /// No description provided for @colorTemperature.
  ///
  /// In ko, this message translates to:
  /// **'색온도'**
  String get colorTemperature;

  /// No description provided for @saturation.
  ///
  /// In ko, this message translates to:
  /// **'채도'**
  String get saturation;

  /// No description provided for @brightness.
  ///
  /// In ko, this message translates to:
  /// **'밝기'**
  String get brightness;

  /// No description provided for @colorHarmony.
  ///
  /// In ko, this message translates to:
  /// **'색상 조화'**
  String get colorHarmony;

  /// No description provided for @compositionAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'구도 분석'**
  String get compositionAnalysis;

  /// No description provided for @balance.
  ///
  /// In ko, this message translates to:
  /// **'균형'**
  String get balance;

  /// No description provided for @toneReport.
  ///
  /// In ko, this message translates to:
  /// **'톤 리포트'**
  String get toneReport;

  /// No description provided for @overallMood.
  ///
  /// In ko, this message translates to:
  /// **'전체 분위기'**
  String get overallMood;

  /// No description provided for @styleCategory.
  ///
  /// In ko, this message translates to:
  /// **'스타일 카테고리'**
  String get styleCategory;

  /// No description provided for @darkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get darkMode;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @error.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// No description provided for @errorAnalysisFailed.
  ///
  /// In ko, this message translates to:
  /// **'분석에 실패했습니다. 다시 시도해 주세요.'**
  String get errorAnalysisFailed;

  /// No description provided for @allStyles.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get allStyles;

  /// No description provided for @deleteAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'분석 삭제'**
  String get deleteAnalysis;

  /// No description provided for @deleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 분석을 삭제하시겠습니까?'**
  String get deleteConfirm;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
