import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/fcm_service.dart';
import 'screens/rrt_profile_setup_screen_prod.dart' as profile;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (gracefully handle configuration errors)
  try {
    await Firebase.initializeApp();
    
    // Set up background message handler only if Firebase is initialized
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // Firebase configuration not found - app will run without Firebase features
    print('Warning: Firebase not configured. Push notifications will not work.');
    print('Error: $e');
  }
  
  runApp(const ProviderScope(child: RRTApp()));
}

class RRTApp extends StatelessWidget {
  const RRTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const profile.RRTProfileSetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
