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
      final requestBody = {
        'udise_code': udiseCode,
        'password': password,
        'role': 'school', // Add role field for school login
      };

      print('=== SCHOOL LOGIN REQUEST DEBUG ===');
      print('Request Body: $requestBody');
      print('URL: ${ApiConfig.loginEndpoint}');

      final response = await http.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('=== SCHOOL LOGIN RESPONSE DEBUG ===');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = json.decode(response.body);
      print('Parsed Data: $data');

      if (data is Map) {
        print('Available fields: ${data.keys}');
        print('Role field: ${data['role']}');
        print('User_type field: ${data['user_type']}');
        print('UserType field: ${data['userType']}');
        print('User_role field: ${data['user_role']}');
      }

      if (response.statusCode == 200) {
        // Extract role from response
        String? userRole = 'teacher'; // Default
        if (data is Map) {
          userRole = data['role']?.toString() ??
              data['user_type']?.toString() ??
              data['userType']?.toString() ??
              data['user_role']?.toString() ??
              'teacher';
          userRole = userRole.toLowerCase().trim();
        }

        print('Extracted role: $userRole');

        // Convert to UserType
        UserType userType;
        switch (userRole) {
          case 'teacher':
          case 'teacher_user':
          case 'school':
          case 'school_admin':
            userType = UserType.teacher;
            break;
          case 'crc':
          case 'supervisor':
          case 'crc_user':
            userType = UserType.crc;
            break;
          default:
            print(
                'WARNING: Unrecognized role: $userRole, defaulting to teacher');
            userType = UserType.teacher;
            break;
        }

        print('Final UserType: $userType');

        _udiseCode = udiseCode;
        _isLoggedIn = true;
        _userType = userType;
        _loggedInUser = (data['schoolName'] as String?)?.isNotEmpty == true
            ? data['schoolName'] as String?
            : null;

        // Navigate based on user type
        switch (userType) {
          case UserType.teacher:
            navigateToScreen(AppScreen.teacherHome);
            break;
          case UserType.crc:
            navigateToScreen(AppScreen.crcHome);
            break;
        }

        notifyListeners();
      } else {
        // Login failed - Add better debugging
        print('=== SCHOOL LOGIN FAILED DEBUG ===');
        print('Full Response: $data');
        print('Status: ${response.statusCode}');
        print('Message: ${data['message']}');

        // Check for message in different locations
        String errorMessage = 'Login failed';
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Handle login success
  void handleLoginSuccess(UserType type,
      {String? username, String? udiseCode}) {
    print('=== HANDLE LOGIN SUCCESS DEBUG ===');
    print('UserType received: $type');
    print('Username: $username');
    print('UDISE Code: $udiseCode');

    _isLoggedIn = true;
    _userType = type;
    _loggedInUser = username;
    _udiseCode = udiseCode; // Store UDISE code

    print('Navigation logic - UserType: $type');

    switch (type) {
      case UserType.teacher:
        print('Navigating to TeacherHome');
        navigateToScreen(AppScreen.teacherHome);
        break;
      case UserType.crc:
        print('Navigating to CRCHome');
        navigateToScreen(AppScreen.crcHome);
        break;
    }

    print('Login success handling completed');
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
