import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

enum UserType { teacher, crc }

enum AppScreen {
  // === SPLASH SCREEN ===
  splash, // Initial splash screen

  // === AUTHENTICATION SECTION ===
  schoolLogin, // Unified school login screen

  // === TEACHER SECTION ===
  teacherHome, // Teacher dashboard/home
  studentsData, // Student information management
  teachersList, // Teacher information management
  certificate, // Certificate generation and management
  newCertificate, // Create new certificates
  photoUpload, // Upload school/activity photos
  newPhotoUpload, // New photo upload interface
  previousPhotos, // View previously uploaded photos

  // === CRC SUPERVISOR SECTION ===
  crcHome, // CRC Supervisor dashboard
  schoolMonitoring, // Monitor schools in CRC area
  teacherReports, // View and manage teacher reports
  dataVerification, // Verify and validate data
  progressTracking, // Track educational progress

  // === SHARED/COMMON SECTION ===
  dashboard, // Common dashboard (if needed)
}

class AppStateProvider extends ChangeNotifier {
  AppScreen _currentScreen = AppScreen.splash;
  final List<AppScreen> _navigationStack = [AppScreen.schoolLogin];
  bool _isLoggedIn = false;
  UserType? _userType;
  String? _loggedInUser;
  String? _udiseCode;
  String? _employeeId;

  // Getters
  AppScreen get currentScreen => _currentScreen;
  bool get isLoggedIn => _isLoggedIn;
  UserType? get userType => _userType;
  String? get loggedInUser => _loggedInUser;
  String? get udiseCode => _udiseCode;
  String? get employeeId => _employeeId;
  bool get canGoBack => _navigationStack.length > 1;

  // Navigation methods
  void navigateToScreen(AppScreen screen) {
    print('Navigation called with screen: $screen');

    if (screen == AppScreen.schoolLogin) {
      _isLoggedIn = false;
      _userType = null;
      _loggedInUser = null;
      _navigationStack.clear();
      _navigationStack.add(screen);
    } else if ((screen == AppScreen.teacherHome ||
            screen == AppScreen.crcHome) &&
        !_isLoggedIn) {
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
  Future<void> login(
      String udiseCode, String employeeId, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'udise_code': udiseCode,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _udiseCode = udiseCode;
        _isLoggedIn = true;
        _userType = UserType.teacher;
        _loggedInUser = (data['schoolName'] as String?) ?? 'Unknown School';
        navigateToScreen(AppScreen.teacherHome);
        notifyListeners();
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Handle login success
  void handleLoginSuccess(UserType type,
      {String? username, String? udiseCode}) {
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
    _employeeId = null;
    _navigationStack.clear();
    _navigationStack.add(AppScreen.schoolLogin);
    navigateToScreen(AppScreen.schoolLogin);
  }

  // Back navigation methods
  void goBackToLogin() {
    navigateToScreen(AppScreen.schoolLogin);
  }

  void goBackToHome() {
    if (_userType == UserType.teacher) {
      navigateToScreen(AppScreen.teacherHome);
    } else if (_userType == UserType.crc) {
      navigateToScreen(AppScreen.crcHome);
    } else {
      navigateToScreen(AppScreen.schoolLogin);
    }
  }
}
