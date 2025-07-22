import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    final quickActions = [
      {
        'id': AppScreen.photoUpload,
        'title': 'फोटो अपलोड',
        'subtitle': 'छात्र + पेड़ + शिक्षिका फोटो',
        'icon': Icons.camera_alt,
        'color': AppTheme.green,
      },
      {
        'id': AppScreen.studentsData,
        'title': 'छात्र रजिस्ट्रेशन',
        'subtitle': 'प्रत्येक छात्र की जानकारी',
        'icon': Icons.people,
        'color': AppTheme.blue,
      },
      {
        'id': AppScreen.certificate,
        'title': 'सर्टिफिकेट डाउनलोड',
        'subtitle': 'छात्रों के लिए प्रमाणपत्र',
        'icon': Icons.card_membership,
        'color': AppTheme.purple,
      },
      {
        'id': AppScreen.previousPhotos,
        'title': 'अपलोडेड फोटो देखें',
        'subtitle': 'पहले अपलोड किए फोटो',
        'icon': Icons.photo_library,
        'color': AppTheme.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('स्वागत, ${appState.loggedInUser ?? "शिक्षक"}'),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
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
                      'एक पेड़ माँ के नाम 2.0',
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
                        childAspectRatio: 1.1,
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
                                  'आपकी प्रगति',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildProgressItem('फोटो अपलोड', '12/15', 0.8),
                            const SizedBox(height: 12),
                            _buildProgressItem('छात्र रजिस्ट्रेशन', '28/30', 0.93),
                            const SizedBox(height: 12),
                            _buildProgressItem('सर्टिफिकेट जेनरेट', '25/28', 0.89),
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
                padding: const EdgeInsets.all(12),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGray.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String progress, double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray,
              ),
            ),
            Text(
              progress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: AppTheme.lightGreen,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.green),
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
