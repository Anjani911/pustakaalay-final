import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  String selectedPeriod = 'thisMonth';
  String selectedSchool = 'all';
  
  // Sample teacher report data
  List<Map<String, dynamic>> teacherReports = [
    {
      'id': 1,
      'teacherName': 'श्रीमती सुनीता शर्मा',
      'schoolName': 'राजकीय प्राथमिक शाला, नारायणपुर',
      'totalStudents': 45,
      'photosUploaded': 89,
      'studentsRegistered': 42,
      'lastLogin': '2 घंटे पहले',
      'activeDays': 22,
      'totalDays': 25,
      'efficiency': 92,
      'status': 'excellent',
    },
    {
      'id': 2,
      'teacherName': 'श्री राजेश कुमार',
      'schoolName': 'राजकीय मध्य शाला, धमतरी',
      'totalStudents': 67,
      'photosUploaded': 134,
      'studentsRegistered': 65,
      'lastLogin': '5 घंटे पहले',
      'activeDays': 20,
      'totalDays': 25,
      'efficiency': 78,
      'status': 'good',
    },
    {
      'id': 3,
      'teacherName': 'श्रीमती प्रिया वर्मा',
      'schoolName': 'राजकीय उच्च शाला, बिलासपुर',
      'totalStudents': 89,
      'photosUploaded': 156,
      'studentsRegistered': 87,
      'lastLogin': '1 दिन पहले',
      'activeDays': 24,
      'totalDays': 25,
      'efficiency': 95,
      'status': 'excellent',
    },
    {
      'id': 4,
      'teacherName': 'श्री अमित पटेल',
      'schoolName': 'राजकीय प्राथमिक शाला, जगदलपुर',
      'totalStudents': 34,
      'photosUploaded': 23,
      'studentsRegistered': 28,
      'lastLogin': '3 दिन पहले',
      'activeDays': 15,
      'totalDays': 25,
      'efficiency': 58,
      'status': 'needs_improvement',
    },
  ];

  List<Map<String, dynamic>> get filteredReports {
    return teacherReports.where((report) {
      final matchesSchool = selectedSchool == 'all' || 
          (report['schoolName'] as String).contains(selectedSchool);
      return matchesSchool;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          appState.goBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('शिक्षक रिपोर्ट'),
          backgroundColor: AppTheme.green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('रिपोर्ट डाउनलोड की गई')),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Filters Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGray,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          'अवधि',
                          selectedPeriod,
                          [
                            {'value': 'thisMonth', 'label': 'इस महीने'},
                            {'value': 'lastMonth', 'label': 'पिछले महीने'},
                            {'value': 'thisQuarter', 'label': 'इस तिमाही'},
                            {'value': 'thisYear', 'label': 'इस वर्ष'},
                          ],
                          (value) => setState(() => selectedPeriod = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          'स्कूल',
                          selectedSchool,
                          [
                            {'value': 'all', 'label': 'सभी स्कूल'},
                            {'value': 'नारायणपुर', 'label': 'नारायणपुर'},
                            {'value': 'धमतरी', 'label': 'धमतरी'},
                            {'value': 'बिलासपुर', 'label': 'बिलासपुर'},
                          ],
                          (value) => setState(() => selectedSchool = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'कुल शिक्षक',
                      filteredReports.length.toString(),
                      Icons.people,
                      AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'सक्रिय',
                      filteredReports.where((r) => r['status'] != 'needs_improvement').length.toString(),
                      Icons.check_circle,
                      AppTheme.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'औसत दक्षता',
                      '${(filteredReports.fold<int>(0, (sum, r) => sum + (r['efficiency'] as int)) / filteredReports.length).round()}%',
                      Icons.analytics,
                      AppTheme.purple,
                    ),
                  ),
                ],
              ),
            ),
            
            // Teacher Reports List
            Expanded(
              child: filteredReports.isEmpty
                  ? const Center(
                      child: Text(
                        'कोई रिपोर्ट नहीं मिली',
                        style: TextStyle(fontSize: 16, color: AppTheme.darkGray),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _buildReportCard(report);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<Map<String, String>> options,
    void Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.gray.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: (newValue) => onChanged(newValue!),
              isExpanded: true,
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(
                    option['label']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.darkGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (report['status']) {
      case 'excellent':
        statusColor = AppTheme.green;
        statusText = 'उत्कृष्ट';
        statusIcon = Icons.star;
        break;
      case 'good':
        statusColor = AppTheme.blue;
        statusText = 'अच्छा';
        statusIcon = Icons.thumb_up;
        break;
      case 'needs_improvement':
        statusColor = AppTheme.orange;
        statusText = 'सुधार की आवश्यकता';
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = AppTheme.gray;
        statusText = 'अज्ञात';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['teacherName'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['schoolName'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.darkGray.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Statistics Row
              Row(
                children: [
                  _buildStatItem(Icons.people, '${report['totalStudents']} छात्र'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.photo_library, '${report['photosUploaded']} फोटो'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.calendar_today, '${report['activeDays']}/${report['totalDays']} दिन'),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Efficiency Bar
              Row(
                children: [
                  const Text(
                    'दक्षता: ',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (report['efficiency'] as int) / 100,
                      backgroundColor: AppTheme.gray.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${report['efficiency']}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Last Login
              Text(
                'अंतिम लॉगिन: ${report['lastLogin']}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGray.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.darkGray.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.darkGray.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.gray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Teacher Header
                  Text(
                    report['teacherName'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report['schoolName'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGray.withOpacity(0.7),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Performance Card
                        _buildDetailCard(
                          'प्रदर्शन विवरण',
                          [
                            _buildDetailRow('कुल छात्र', '${report['totalStudents']}'),
                            _buildDetailRow('रजिस्टर्ड छात्र', '${report['studentsRegistered']}'),
                            _buildDetailRow('अपलोडेड फोटो', '${report['photosUploaded']}'),
                            _buildDetailRow('दक्षता स्कोर', '${report['efficiency']}%'),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Activity Card
                        _buildDetailCard(
                          'गतिविधि विवरण',
                          [
                            _buildDetailRow('सक्रिय दिन', '${report['activeDays']}'),
                            _buildDetailRow('कुल दिन', '${report['totalDays']}'),
                            _buildDetailRow('उपस्थिति प्रतिशत', '${((report['activeDays'] as int) * 100 / (report['totalDays'] as int)).round()}%'),
                            _buildDetailRow('अंतिम लॉगिन', report['lastLogin'] as String),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${report['teacherName'] as String} को संदेश भेजा गया')),
                                  );
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('संदेश भेजें'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${report['teacherName'] as String} से संपर्क किया गया')),
                                  );
                                },
                                icon: const Icon(Icons.phone),
                                label: const Text('कॉल करें'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.darkGray.withOpacity(0.7),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
