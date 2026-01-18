/// App-wide constants and configurations
class AppConstants {
  // App Information
  static const String appName = 'RRT SOS Alert';
  static const String appSubtitle = 'Rapid Response Team';
  static const String appVersion = '1.0.0';
  
  // Navigation Routes
  static const String homeRoute = '/home';
  static const String alertsRoute = '/alerts';
  static const String profileRoute = '/profile';
  static const String onboardingRoute = '/onboarding';
  static const String profileCreateRoute = '/profile-create';
  
  // Firebase Topic Prefixes
  static const String districtTopicPrefix = 'district-';
  
  // Database Tables
  static const String userTableName = 'user_profile';
  static const String alertsTableName = 'alerts';
  
  // API Endpoints (Backend)
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Location Settings
  static const double locationAccuracy = 100.0; // meters
  static const Duration locationTimeout = Duration(seconds: 15);
  
  // SOS States
  static const String sosLocked = 'locked';
  static const String sosReady = 'ready';
  static const String sosActive = 'active';
  
  // Alert Status
  static const String alertActive = 'active';
  static const String alertResolved = 'resolved';
  
  // Design Token UI Constants
  static const double screenMargins = 24.0; // Left/right screen margins
  static const double iconTopMargin = 48.0; // Icon top margin
  static const double iconBrandSpacing = 16.0; // Between icon and branding
  static const double brandBodySpacing = 32.0; // Between branding and body
  static const double fieldSpacing = 24.0; // Between input fields
  static const double buttonBottomMargin = 24.0; // Button to bottom edge
  
  // Component Sizes
  static const double brandIconSize = 48.0; // Branding icon size
  static const double primaryButtonHeight = 64.0; // Primary button height
  static const double navBarHeight = 80.0; // Navigation bar height
  
  // Legacy constants for compatibility
  static const double defaultPadding = screenMargins;
  static const double defaultRadius = 8.0;
  static const double sosButtonSize = 200.0;
  static const double cardBorderRadius = 12.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration sosActivationDelay = Duration(seconds: 3);
}