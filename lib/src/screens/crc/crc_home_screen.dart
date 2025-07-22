import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class CRCHomeScreen extends StatelessWidget {
  const CRCHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    final supervisorActions = [
      {
        'id': AppScreen.schoolMonitoring,
        'title': 'स्कूल मॉनिटरिंग',
        'subtitle': 'स्कूलों की निगरानी और जांच',
        'icon': Icons.school,
        'color': AppTheme.blue,
      },
      {
        'id': AppScreen.teacherReports,
        'title': 'शिक्षक रिपोर्ट',
        'subtitle': 'शिक्षकों की गतिविधि रिपोर्ट',
        'icon': Icons.assessment,
        'color': AppTheme.green,
      },
      {
        'id': AppScreen.dataVerification,
        'title': 'डेटा वेरिफिकेशन',
        'subtitle': 'अपलोड किए गए डेटा की जांच',
        'icon': Icons.verified,
        'color': AppTheme.purple,
      },
      {
        'id': AppScreen.progressTracking,
        'title': 'प्रगति ट्रैकिंग',
        'subtitle': 'जिले की समग्र प्रगति',
        'icon': Icons.track_changes,
        'color': AppTheme.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('स्वागत, ${appState.loggedInUser ?? "सुपरवाइजर"}'),
        backgroundColor: AppTheme.blue,
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
                  color: AppTheme.blue,
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
                        Icons.supervisor_account,
                        size: 50,
                        color: AppTheme.blue,
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
                      'सुपरवाइजर डैशबोर्ड',
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
                      'निगरानी कार्य',
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
                      itemCount: supervisorActions.length,
                      itemBuilder: (context, index) {
                        final action = supervisorActions[index];
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
                    
                    // Statistics section
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
                                  Icons.analytics,
                                  color: AppTheme.blue,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'जिला सांख्यिकी',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGray,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'कुल स्कूल',
                                    '145',
                                    Icons.school,
                                    AppTheme.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'सक्रिय शिक्षक',
                                    '342',
                                    Icons.people,
                                    AppTheme.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'अपलोडेड फोटो',
                                    '1,248',
                                    Icons.photo_library,
                                    AppTheme.purple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard(
                                    'रजिस्टर्ड छात्र',
                                    '8,756',
                                    Icons.child_care,
                                    AppTheme.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Recent activities
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
                            const Text(
                              'हाल की गतिविधि',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGray,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildActivityItem(
                              'राजकीय प्राथमिक शाला, नारायणपुर',
                              '25 फोटो अपलोड किए गए',
                              '2 घंटे पहले',
                              Icons.photo_camera,
                              AppTheme.green,
                            ),
                            const Divider(),
                            
                            _buildActivityItem(
                              'राजकीय मध्य शाला, रायपुर',
                              '15 छात्र रजिस्टर किए गए',
                              '4 घंटे पहले',
                              Icons.person_add,
                              AppTheme.blue,
                            ),
                            const Divider(),
                            
                            _buildActivityItem(
                              'राजकीय उच्च शाला, धमतरी',
                              'डेटा वेरिफिकेशन पूर्ण',
                              '6 घंटे पहले',
                              Icons.verified,
                              AppTheme.purple,
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
          // Navigate to real CRC screens
          appState.navigateToScreen(screen);
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.darkGray.withOpacity(0.5),
            ),
          ),
        ],
      ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blue,
              ),
              child: const Text('लॉगआउट'),
            ),
          ],
        );
      },
    );
  }
}
