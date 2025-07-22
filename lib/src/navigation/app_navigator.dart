import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

// === AUTHENTICATION SCREENS ===
import '../screens/auth/user_type_selection_screen.dart';
import '../screens/auth/teacher_login_screen.dart';
import '../screens/auth/crc_login_screen.dart';

// === TEACHER SCREENS ===
import '../screens/teacher/teacher_home_screen.dart';
import '../screens/teacher/students_data_screen.dart';
import '../screens/teacher/certificate_screen.dart';
import '../screens/teacher/new_certificate_screen.dart';
import '../screens/teacher/photo_upload_screen.dart';
import '../screens/teacher/new_photo_upload_screen.dart';
import '../screens/teacher/previous_photos_screen.dart';

// === CRC SUPERVISOR SCREENS ===
import '../screens/crc/crc_home_screen.dart';
import '../screens/crc/school_monitoring_screen.dart';
import '../screens/crc/teacher_reports_screen.dart';
import '../screens/crc/data_verification_screen.dart';
import '../screens/crc/progress_tracking_screen.dart';

// === SHARED/COMMON SCREENS ===
import '../screens/shared/dashboard_screen.dart';

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              if (appState.canGoBack) {
                appState.goBack();
              } else {
                // If can't go back, exit the app
                Navigator.of(context).pop();
              }
            }
          },
          child: _buildCurrentScreen(context, appState),
        );
      },
    );
  }

  Widget _buildCurrentScreen(BuildContext context, AppStateProvider appState) {
    print('Rendering screen: ${appState.currentScreen}');
    
    switch (appState.currentScreen) {
      
      // === AUTHENTICATION SECTION ===
      case AppScreen.userTypeSelection:
        return const UserTypeSelectionScreen();
      
      case AppScreen.teacherLogin:
        return const TeacherLoginScreen();
      
      case AppScreen.crcLogin:
        return const CRCLoginScreen();
      
      // === TEACHER SECTION ===
      case AppScreen.teacherHome:
        return const TeacherHomeScreen();
      
      case AppScreen.studentsData:
        return const StudentsDataScreen();
      
      case AppScreen.certificate:
        return const CertificateScreen();
      
      case AppScreen.newCertificate:
        return const NewCertificateScreen();
      
      case AppScreen.photoUpload:
        return const PhotoUploadScreen();
      
      case AppScreen.newPhotoUpload:
        return const NewPhotoUploadScreen();
      
      case AppScreen.previousPhotos:
        return const PreviousPhotosScreen();
      
      // === CRC SUPERVISOR SECTION ===
      case AppScreen.crcHome:
        return const CRCHomeScreen();
      
      case AppScreen.schoolMonitoring:
        return const SchoolMonitoringScreen();
      
      case AppScreen.teacherReports:
        return const TeacherReportsScreen();
      
      case AppScreen.dataVerification:
        return const DataVerificationScreen();
      
      case AppScreen.progressTracking:
        return const ProgressTrackingScreen();
      
      // === SHARED/COMMON SECTION ===
      case AppScreen.dashboard:
        return const DashboardScreen();
    }
  }
}
