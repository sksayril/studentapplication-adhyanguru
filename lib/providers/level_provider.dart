import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/education_level.dart';

class LevelProvider with ChangeNotifier {
  String? _currentLevel;
  static const String _levelKey = 'student_level';
  
  String? get currentLevel => _currentLevel;
  
  LevelProvider() {
    _loadLevel();
  }
  
  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    // Try to get from student_level first (from API), then fallback to education_level
    _currentLevel = prefs.getString(_levelKey) ?? 
                    prefs.getString('education_level') ?? 
                    EducationLevel.intermediate;
    notifyListeners();
  }
  
  Future<void> setLevel(String level) async {
    _currentLevel = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_levelKey, level);
    await prefs.setString('education_level', level); // Also save to education_level for compatibility
    notifyListeners();
  }
  
  Future<void> clearLevel() async {
    _currentLevel = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_levelKey);
    await prefs.remove('education_level');
    notifyListeners();
  }
  
  bool get isJunior => _currentLevel?.toLowerCase() == EducationLevel.junior.toLowerCase();
  bool get isIntermediate => _currentLevel?.toLowerCase() == EducationLevel.intermediate.toLowerCase();
  bool get isSenior => _currentLevel?.toLowerCase() == EducationLevel.senior.toLowerCase();
}

