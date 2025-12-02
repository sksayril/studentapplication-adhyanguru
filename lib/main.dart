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
import 'services/auth_service.dart';
import 'utils/theme_provider.dart';
import 'providers/level_provider.dart';
import 'utils/education_level.dart';

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
        
        final data = snapshot.data ?? {'isLoggedIn': false, 'level': null};
        final isLoggedIn = data['isLoggedIn'] as bool;
        final level = data['level'] as String?;
        
        // If user is logged in, go to appropriate home screen based on level
        if (isLoggedIn) {
          if (level?.toLowerCase() == EducationLevel.junior.toLowerCase()) {
            return const JuniorHomeScreen();
          } else {
            return const HomeScreen();
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
      return {'isLoggedIn': false, 'level': null};
    }
    
    // Get level from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString('student_level') ?? 
                  prefs.getString('education_level');
    
    return {'isLoggedIn': true, 'level': level};
  }
}
