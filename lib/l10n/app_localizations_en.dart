// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GAMDO';

  @override
  String get onboardingTitle1 => 'Read Photo Aesthetics';

  @override
  String get onboardingDesc1 =>
      'AI analyzes colors, composition, and mood\nto discover your unique photo sense.';

  @override
  String get onboardingTitle2 => 'Personalized Coaching';

  @override
  String get onboardingDesc2 =>
      'Upgrade your photography skills\nwith shooting tips and editing guides.';

  @override
  String get onboardingTitle3 => 'Track Your Style';

  @override
  String get onboardingDesc3 =>
      'Track the evolution of your\nphoto style through analysis history.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get analyze => 'Analyze';

  @override
  String get recentAnalysis => 'Recent Analysis';

  @override
  String get noAnalysisYet => 'No photos analyzed yet';

  @override
  String get startFirstAnalysis => 'Analyze your first photo!';

  @override
  String get selectPhoto => 'Select Photo';

  @override
  String get fromGallery => 'Choose from Gallery';

  @override
  String get fromCamera => 'Take a Photo';

  @override
  String get startAnalysis => 'Start Analysis';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analyzingDesc => 'AI is analyzing your photo';

  @override
  String get analysisComplete => 'Analysis Complete';

  @override
  String get colorAnalysis => 'Color Analysis';

  @override
  String get dominantColors => 'Dominant Colors';

  @override
  String get colorTemperature => 'Color Temperature';

  @override
  String get saturation => 'Saturation';

  @override
  String get brightness => 'Brightness';

  @override
  String get colorHarmony => 'Color Harmony';

  @override
  String get compositionAnalysis => 'Composition Analysis';

  @override
  String get compositionTechnique => 'Composition Technique';

  @override
  String get balance => 'Balance';

  @override
  String get strengths => 'Strengths';

  @override
  String get improvements => 'Improvements';

  @override
  String get toneReport => 'Tone Report';

  @override
  String get overallMood => 'Overall Mood';

  @override
  String get styleCategory => 'Style Category';

  @override
  String get shootingTips => 'Shooting Tips';

  @override
  String get editingTips => 'Editing Tips';

  @override
  String get overallScore => 'Overall Score';

  @override
  String get warm => 'Warm';

  @override
  String get cool => 'Cool';

  @override
  String get neutral => 'Neutral';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get apiSettings => 'API Settings';

  @override
  String get proxyUrl => 'Proxy Server URL';

  @override
  String get appToken => 'App Token';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get errorAnalysisFailed => 'Analysis failed. Please try again.';

  @override
  String get errorNetworkFailed => 'Please check your network connection.';

  @override
  String get errorImageTooLarge => 'Image size is too large.';

  @override
  String get allStyles => 'All';

  @override
  String get filterByStyle => 'Filter by Style';

  @override
  String get deleteAnalysis => 'Delete Analysis';

  @override
  String get deleteConfirm => 'Are you sure you want to delete this analysis?';

  @override
  String get delete => 'Delete';

  @override
  String points(int score) {
    return '$score pts';
  }
}
