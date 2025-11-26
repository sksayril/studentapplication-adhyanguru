import 'package:shared_preferences/shared_preferences.dart';

class EducationLevel {
  static const String junior = 'Junior';
  static const String intermediate = 'Intermediate';
  static const String senior = 'Senior';

  static Future<String> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('education_level') ?? intermediate;
  }

  static Future<void> setLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('education_level', level);
  }

  static Future<void> clearLevel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('education_level');
  }

  static String getLevelDescription(String level) {
    switch (level) {
      case junior:
        return 'Class 5 to 10';
      case intermediate:
        return 'Class 11 to Graduation';
      case senior:
        return 'Masters to PhD';
      default:
        return '';
    }
  }

  static String getLevelEmoji(String level) {
    switch (level) {
      case junior:
        return '🎒';
      case intermediate:
        return '🎓';
      case senior:
        return '👨‍🎓';
      default:
        return '🎓';
    }
  }
}

