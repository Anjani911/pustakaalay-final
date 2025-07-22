import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';

class DataVerificationScreen extends StatefulWidget {
  const DataVerificationScreen({super.key});

  @override
  State<DataVerificationScreen> createState() => _DataVerificationScreenState();
}

class _DataVerificationScreenState extends State<DataVerificationScreen> {
  String selectedStatus = 'all';
  
  List<Map<String, dynamic>> verificationData = [
    {
      'id': 1,
      'schoolName': 'राजकीय प्राथमिक शाला, नारायणपुर',
      'teacherName': 'श्रीमती सुनीता शर्मा',
      'submissionDate': '15 नवंबर 2024',
      'dataType': 'छात्र रजिस्ट्रेशन',
      'recordCount': 42,
      'status': 'pending',
      'priority': 'high',
    },
    {
      'id': 2,
      'schoolName': 'राजकीय मध्य शाला, धमतरी',
      'teacherName': 'श्री राजेश कुमार',
      'submissionDate': '14 नवंबर 2024',
      'dataType': 'फोटो अपलोड',
      'recordCount': 89,
      'status': 'verified',
      'priority': 'medium',
    },
    {
      'id': 3,
      'schoolName': 'राजकीय उच्च शाला, बिलासपुर',
      'teacherName': 'श्रीमती प्रिया वर्मा',
      'submissionDate': '13 नवंबर 2024',
      'dataType': 'छात्र डेटा अपडेट',
      'recordCount': 156,
      'status': 'rejected',
      'priority': 'low',
    },
  ];

  List<Map<String, dynamic>> get filteredData {
    return verificationData.where((data) {
      return selectedStatus == 'all' || data['status'] == selectedStatus;
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
          title: const Text('डेटा वेरिफिकेशन'),
          backgroundColor: AppTheme.purple,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => appState.goBack(),
          ),
        ),
        body: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.lightGray,
              child: Row(
                children: [
                  _buildFilterChip('सभी', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('लंबित', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('सत्यापित', 'verified'),
                  const SizedBox(width: 8),
                  _buildFilterChip('अस्वीकृत', 'rejected'),
                ],
              ),
            ),
            
            // Data List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredData.length,
                itemBuilder: (context, index) {
                  final data = filteredData[index];
                  return _buildDataCard(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedStatus = value;
        });
      },
      backgroundColor: AppTheme.white,
      selectedColor: AppTheme.purple.withOpacity(0.2),
      checkmarkColor: AppTheme.purple,
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    Color statusColor;
    String statusText;
    switch (data['status']) {
      case 'pending':
        statusColor = AppTheme.orange;
        statusText = 'लंबित';
        break;
      case 'verified':
        statusColor = AppTheme.green;
        statusText = 'सत्यापित';
        break;
      case 'rejected':
        statusColor = AppTheme.red;
        statusText = 'अस्वीकृत';
        break;
      default:
        statusColor = AppTheme.gray;
        statusText = 'अज्ञात';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['schoolName'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('शिक्षक: ${data['teacherName']}'),
            Text('डेटा प्रकार: ${data['dataType']}'),
            Text('रिकॉर्ड संख्या: ${data['recordCount']}'),
            Text('जमा दिनांक: ${data['submissionDate']}'),
            const SizedBox(height: 12),
            if (data['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyData(data['id'] as int),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                      ),
                      child: const Text('सत्यापित करें'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectData(data['id'] as int),
                      child: const Text('अस्वीकार करें'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _verifyData(int id) {
    setState(() {
      final index = verificationData.indexWhere((data) => data['id'] == id);
      if (index != -1) {
        verificationData[index]['status'] = 'verified';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('डेटा सत्यापित किया गया')),
    );
  }

  void _rejectData(int id) {
    setState(() {
      final index = verificationData.indexWhere((data) => data['id'] == id);
      if (index != -1) {
        verificationData[index]['status'] = 'rejected';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('डेटा अस्वीकार किया गया')),
    );
  }
}
