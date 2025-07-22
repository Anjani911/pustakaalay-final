import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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
          _errorMessage = result['data']?['message']?.toString() ?? 'डैशबोर्ड डेटा लोड नहीं हो सका';
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
        'id': AppScreen.photoUpload,
        'title': 'छात्र रजिस्ट्रेशन',
        'subtitle': 'नए छात्र का पंजीकरण करें',
        'icon': Icons.person_add,
        'color': AppTheme.green,
      },
      {
        'id': AppScreen.studentsData,
        'title': 'छात्र विवरण',
        'subtitle': 'छात्रों की जानकारी देखें',
        'icon': Icons.people,
        'color': AppTheme.blue,
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
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: quickActions.length,
                      itemBuilder: (context, index) {
                        final action = quickActions[index];
                        return _buildActionCard(
                          context,
                          appState,
                          action['title'] as String,
                          action['subtitle'] as String,
                          action['icon'] as IconData,
                          action['color'] as Color,
                          action['id'] as AppScreen,
                        );
                      },
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
                                              label: const Text('पुनः प्रयास करें'),
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

  Widget _buildActionCard(
    BuildContext context,
    AppStateProvider appState,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    AppScreen screen,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          if (screen == AppScreen.photoUpload) {
            // Photo upload is implemented, navigate normally
            appState.navigateToScreen(screen);
          } else {
            // Other features are now implemented too!
            appState.navigateToScreen(screen);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.darkGray.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String count, IconData icon, Color color) {
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
