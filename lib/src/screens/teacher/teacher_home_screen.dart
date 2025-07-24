import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../services/teacher_service.dart';

enum ActionType {
  studentRegistration,
  studentDetails,
  teacherDetails,
}

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _hasPhotoUpdatesNeeded = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _checkForPhotoUpdates(); // Check for pending photo updates
  }

  Future<void> _checkForPhotoUpdates() async {
    final hasUpdates = await _hasStudentsWithPendingPhotos();
    setState(() {
      _hasPhotoUpdatesNeeded = hasUpdates;
    });
  }

  Future<bool> _hasStudentsWithPendingPhotos() async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode ?? "22010100101";

      final result = await ApiService.getStudentsByUdise(udiseCode);

      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];
        if (responseData['status'] == true && responseData['data'] != null) {
          final studentsList = responseData['data'] as List;

          // Check if any student needs photo update (7+ days)
          for (var student in studentsList) {
            if (_isStudentPhotoUpdateRequired(
                student as Map<String, dynamic>)) {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  bool _isStudentPhotoUpdateRequired(Map<String, dynamic> student) {
    try {
      final dateTimeString = student['date_time']?.toString();
      if (dateTimeString == null || dateTimeString.isEmpty) return false;

      final registrationDate = DateTime.parse(dateTimeString);
      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(registrationDate).inDays;

      return daysDifference >= 7;
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode ?? "1234";

      final result = await ApiService.getTeacherDashboard(udiseCode);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _dashboardData = Map<String, dynamic>.from(result['data'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['data']?['message']?.toString() ??
              'डैशबोर्ड डेटा लोड नहीं हो सका';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'नेटवर्क एरर: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    // Get student count from dashboard data, fallback to 0
    final studentCount = _dashboardData?['COUNT'] ?? 0;
    final photoUploads = studentCount * 2; // Twice the student count

    final quickActions = [
      {
        'id': ActionType.studentRegistration,
        'title': 'छात्र रजिस्ट्रेशन',
        'subtitle': 'नए छात्र का पंजीकरण करें',
        'icon': Icons.person_add,
        'color': AppTheme.green,
        'screen': AppScreen.photoUpload,
      },
      {
        'id': ActionType.studentDetails,
        'title': 'छात्र विवरण',
        'subtitle': 'छात्रों की जानकारी देखें',
        'icon': Icons.people,
        'color': AppTheme.blue,
        'screen': AppScreen.studentsData,
        'hasAlert': _hasPhotoUpdatesNeeded, // Add alert flag
      },
      {
        'id': ActionType.teacherDetails,
        'title': 'शिक्षक',
        'subtitle': 'शिक्षक विवरण देखें',
        'icon': Icons.school,
        'color': AppTheme.primaryGreen,
        'screen': AppScreen.teachersList,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('स्वागत, ${appState.loggedInUser ?? "शिक्षक"}'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, appState),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.white,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'हरिहर पाठशाला',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'शिक्षक डैशबोर्ड',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              // Quick actions grid
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'मुख्य कार्य',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vertical Cards Layout
                    Column(
                      children: quickActions.map((action) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: () {
                                final actionType = action['id'] as ActionType;
                                final screen = action['screen'] as AppScreen?;

                                if (screen != null) {
                                  appState.navigateToScreen(screen);
                                } else if (actionType ==
                                    ActionType.teacherDetails) {
                                  _showTeacherDetails(context);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      (action['color'] as Color)
                                          .withOpacity(0.1),
                                      (action['color'] as Color)
                                          .withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: action['color'] as Color,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        action['icon'] as IconData,
                                        color: AppTheme.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  action['title'] as String,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.darkGray,
                                                  ),
                                                ),
                                              ),
                                              // RED ALERT ICON for students data card
                                              if (action['hasAlert'] ==
                                                  true) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.red
                                                            .withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.camera_alt,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            action['subtitle'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.darkGray
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          // Warning text for students data card
                                          if (action['hasAlert'] == true) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '⚠️ कुछ छात्रों की नई फोटो चाहिए',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppTheme.darkGray.withOpacity(0.5),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // Progress section
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: AppTheme.green,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'प्रगति',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primaryGreen,
                                    ),
                                  )
                                : _errorMessage.isNotEmpty
                                    ? Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              _errorMessage,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            TextButton.icon(
                                              onPressed: _fetchDashboardData,
                                              icon: const Icon(Icons.refresh),
                                              label: const Text(
                                                  'पुनः प्रयास करें'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: _buildProgressItem(
                                              'फोटो अपलोड',
                                              '${photoUploads}',
                                              Icons.camera_alt,
                                              AppTheme.green,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: _buildProgressItem(
                                              'छात्र रजिस्ट्रेशन',
                                              '${studentCount}',
                                              Icons.person_add,
                                              AppTheme.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(
      String title, String count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.darkGray,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<void> _showTeacherDetails(BuildContext context) async {
    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final result =
          await TeacherService.getTeacherDetails(appState.udiseCode ?? "");

      if (result['success'] == true && mounted) {
        final teacherData = Map<String, dynamic>.from(result['data'] as Map);
        _showTeacherDetailsDialog(context, teacherData);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((result['message'] as String?) ??
                  'शिक्षक विवरण प्राप्त करने में त्रुटि'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showTeacherDetailsDialog(
      BuildContext context, Map<String, dynamic> teacherData) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // प्रदर्शन विवरण Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'प्रदर्शन विवरण',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGray,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                              'नाम',
                              (teacherData['name'] as String?) ??
                                  'Not Available'),
                          _buildInfoRow(
                              'विद्यालय',
                              (teacherData['school_name'] as String?) ??
                                  'Not Available'),
                          _buildInfoRow('पंजीकृत छात्र',
                              '${(teacherData['registered_students'] as int?) ?? 0}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // संपर्क विवरण Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'संपर्क विवरण',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGray,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                              'नाम',
                              (teacherData['name'] as String?) ??
                                  'Not Available'),
                          _buildInfoRow(
                              'मोबाइल नंबर',
                              (teacherData['mobile'] as String?) ??
                                  'Not Available'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(
                                    teacherData['mobile'] as String?),
                                icon: const Icon(Icons.phone),
                                label: const Text('कॉल करें'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.green,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _sendSMS(teacherData['mobile'] as String?),
                                icon: const Icon(Icons.message),
                                label: const Text('SMS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('बंद करें'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showLogoutDialog(BuildContext context, AppStateProvider appState) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('लॉगआउट'),
          content: const Text('क्या आप वाकई लॉगआउट करना चाहते हैं?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('रद्द करें'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.logout();
              },
              child: const Text('लॉगआउट'),
            ),
          ],
        );
      },
    );
  }
}
