import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/intro_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/junior_splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/junior_home_screen.dart';
import 'screens/board_selection_screen.dart';
import 'services/auth_service.dart';
import 'utils/theme_provider.dart';
import 'providers/level_provider.dart';
import 'utils/education_level.dart';
import 'utils/app_navigator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LevelProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Adhyan Guru',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const InitialScreen(),
        );
      },
    );
  }
}

class InitialScreen extends StatelessWidget {
  const InitialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkAuthenticationAndLevel(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final data = snapshot.data ?? {'isLoggedIn': false, 'level': null, 'ui': null, 'hasBoard': false};
        final isLoggedIn = data['isLoggedIn'] as bool;
        final level = data['level'] as String?;
        final ui = data['ui'] as int?;
        final hasBoard = data['hasBoard'] as bool? ?? false;
        
        // If user is logged in, check if board selection is needed
        if (isLoggedIn) {
          // If no board is selected, show board selection wrapper
          if (!hasBoard) {
            return BoardSelectionWrapper(
              selectedLevel: level ?? 'Primary',
              ui: ui,
            );
          }
          
          // If board is selected, go to appropriate home screen based on UI value
          // UI 1 = Junior UI, UI 2 = Second UI (Senior/Intermediate)
          if (ui == 1) {
            return const JuniorHomeScreen();
          } else if (ui == 2) {
            return const HomeScreen();
          } else {
            // Fallback to level-based navigation if UI is not available
            if (level?.toLowerCase() == EducationLevel.junior.toLowerCase()) {
              return const JuniorHomeScreen();
            } else {
              return const HomeScreen();
            }
          }
        }
        
        // If not logged in, show login screen
        return const LoginScreen();
      },
    );
  }

  Future<Map<String, dynamic>> _checkAuthenticationAndLevel() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!isLoggedIn) {
      return {'isLoggedIn': false, 'level': null, 'ui': null, 'hasBoard': false};
    }
    
    // Get UI and level from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final ui = prefs.getInt('student_ui');
    final level = prefs.getString('student_level') ?? 
                  prefs.getString('education_level');
    
    // If UI is not saved, try to get it from user data
    int? uiValue = ui;
    if (uiValue == null) {
      final userData = await AuthService.getUserData();
      if (userData != null && userData['ui'] != null) {
        uiValue = userData['ui'] as int?;
        // Save it for future use
        if (uiValue != null) {
          await prefs.setInt('student_ui', uiValue);
        }
      }
    }
    
    // Check if board is selected
    final selectedBoardId = await AuthService.getSelectedBoardId();
    final hasBoard = selectedBoardId != null && selectedBoardId.isNotEmpty;
    
    return {'isLoggedIn': true, 'level': level, 'ui': uiValue, 'hasBoard': hasBoard};
  }
}

// Wrapper widget to handle board selection and navigation
class BoardSelectionWrapper extends StatefulWidget {
  final String selectedLevel;
  final int? ui;
  
  const BoardSelectionWrapper({
    Key? key,
    required this.selectedLevel,
    this.ui,
  }) : super(key: key);

  @override
  State<BoardSelectionWrapper> createState() => _BoardSelectionWrapperState();
}

class _BoardSelectionWrapperState extends State<BoardSelectionWrapper> {
  @override
  void initState() {
    super.initState();
    // Navigate to board selection screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToBoardSelection();
    });
  }

  void _navigateToBoardSelection() async {
    final boardId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BoardSelectionScreen(
          selectedLevel: widget.selectedLevel,
        ),
      ),
    );

    // If board was selected, navigate to home screen
    if (boardId != null && boardId.isNotEmpty && mounted) {
      Widget homeScreen;
      if (widget.ui == 1) {
        homeScreen = const JuniorHomeScreen();
      } else if (widget.ui == 2) {
        homeScreen = const HomeScreen();
      } else {
        // Fallback to level-based navigation
        final level = widget.selectedLevel.toLowerCase();
        if (level == EducationLevel.junior.toLowerCase()) {
          homeScreen = const JuniorHomeScreen();
        } else {
          homeScreen = const HomeScreen();
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homeScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while navigating
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
