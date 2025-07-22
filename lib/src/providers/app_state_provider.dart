import 'package:flutter/material.dart';

enum UserType { teacher, crc }

enum AppScreen {
  // === SPLASH SCREEN ===
  splash,                // Initial splash screen
  
  // === AUTHENTICATION SECTION ===
  userTypeSelection,      // Main entry point - user type selection
  teacherLogin,          // Teacher authentication
  crcLogin,              // CRC Supervisor authentication
  
  // === TEACHER SECTION ===
  teacherHome,           // Teacher dashboard/home
  studentsData,          // Student information management
  certificate,           // Certificate generation and management
  newCertificate,        // Create new certificates
  photoUpload,           // Upload school/activity photos
  newPhotoUpload,        // New photo upload interface
  previousPhotos,        // View previously uploaded photos
  
  // === CRC SUPERVISOR SECTION ===
  crcHome,               // CRC Supervisor dashboard
  schoolMonitoring,      // Monitor schools in CRC area
  teacherReports,        // View and manage teacher reports
  dataVerification,      // Verify and validate data
  progressTracking,      // Track educational progress
  
  // === SHARED/COMMON SECTION ===
  dashboard,             // Common dashboard (if needed)
}

class AppStateProvider extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.splash;
  final List<AppScreen> _navigationStack = [AppScreen.userTypeSelection];
  bool _isLoggedIn = false;
  UserType? _userType;
  String? _loggedInUser;
  String? _udiseCode; // Store UDISE code for teacher login

  // Getters
  AppScreen get currentScreen => _currentScreen;
  bool get isLoggedIn => _isLoggedIn;
  UserType? get userType => _userType;
  String? get loggedInUser => _loggedInUser;
  String? get udiseCode => _udiseCode;
  bool get canGoBack => _navigationStack.length > 1;

  // Navigation methods
  void navigateToScreen(AppScreen screen) {
    print('Navigation called with screen: $screen');
    
    if (screen == AppScreen.userTypeSelection) {
      _isLoggedIn = false;
      _userType = null;
      _loggedInUser = null;
      _navigationStack.clear();
      _navigationStack.add(screen);
    } else if ((screen == AppScreen.teacherHome || screen == AppScreen.crcHome) && !_isLoggedIn) {
      _isLoggedIn = true;
      // Replace the current screen in stack for login -> home transition
      if (_navigationStack.isNotEmpty) {
        _navigationStack.removeLast();
      }
      _navigationStack.add(screen);
    } else {
      // Normal navigation - add to stack
      _navigationStack.add(screen);
    }
    
    _currentScreen = screen;
    print('Current screen set to: $screen');
    print('Navigation stack: $_navigationStack');
    notifyListeners();
  }

  // Back navigation
  void goBack() {
    if (_navigationStack.length > 1) {
      _navigationStack.removeLast();
      _currentScreen = _navigationStack.last;
      print('Going back to: $_currentScreen');
      print('Navigation stack: $_navigationStack');
      notifyListeners();
    }
  }

  // Handle user type selection
  void selectUserType(UserType type) {
    _userType = type;
    switch (type) {
      case UserType.teacher:
        navigateToScreen(AppScreen.teacherLogin);
        break;
      case UserType.crc:
        navigateToScreen(AppScreen.crcLogin);
        break;
    }
  }

  // Handle login success
  void handleLoginSuccess(UserType type, {String? username, String? udiseCode}) {
    _isLoggedIn = true;
    _userType = type;
    _loggedInUser = username;
    _udiseCode = udiseCode; // Store UDISE code
    
    switch (type) {
      case UserType.teacher:
        navigateToScreen(AppScreen.teacherHome);
        break;
      case UserType.crc:
        navigateToScreen(AppScreen.crcHome);
        break;
    }
  }

  // Handle logout
  void logout() {
    _isLoggedIn = false;
    _userType = null;
    _loggedInUser = null;
    _udiseCode = null; // Clear UDISE code on logout
    _navigationStack.clear();
    _navigationStack.add(AppScreen.userTypeSelection);
    navigateToScreen(AppScreen.userTypeSelection);
  }

  // Back navigation methods
  void goBackToUserSelection() {
    navigateToScreen(AppScreen.userTypeSelection);
  }

  void goBackToHome() {
    if (_userType == UserType.teacher) {
      navigateToScreen(AppScreen.teacherHome);
    } else if (_userType == UserType.crc) {
      navigateToScreen(AppScreen.crcHome);
    } else {
      navigateToScreen(AppScreen.userTypeSelection);
    }
  }
}
