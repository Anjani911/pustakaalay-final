import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    
    final loginOptions = [
      {
        'id': UserType.teacher,
        'title': 'शिक्षक लॉगिन',
        'subtitle': 'Teacher Login Portal',
        'description': 'पेड़ लगाने वाले शिक्षकों के लिए',
        'bgColor': AppTheme.green,
        'lightColor': AppTheme.lightGreen,
      },
      {
        'id': UserType.crc,
        'title': 'सुपरवाइजर लॉगिन',
        'subtitle': 'Supervisor Login Portal',
        'description': 'स्कूल निगरानी अधिकारी',
        'bgColor': AppTheme.blue,
        'lightColor': AppTheme.lightBlue,
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      '🌳',
                      style: TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'एक पेड़ माँ के नाम 2.0',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'रायपुर जिला शिक्षा पोर्टल',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 2,
                      width: 60,
                      color: AppTheme.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'अपने रोल का चयन करें',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Login Options
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: loginOptions.map((option) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        color: option['lightColor'] as Color,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => appState.selectUserType(option['id'] as UserType),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option['title'] as String,
                                            style: TextStyle(
                                              color: option['bgColor'] as Color,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            option['subtitle'] as String,
                                            style: const TextStyle(
                                              color: AppTheme.darkGray,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: option['bgColor'] as Color,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward,
                                        color: AppTheme.white,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  option['description'] as String,
                                  style: const TextStyle(
                                    color: AppTheme.darkGray,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
