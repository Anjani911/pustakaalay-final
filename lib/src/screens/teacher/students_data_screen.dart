import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class StudentsDataScreen extends StatefulWidget {
  const StudentsDataScreen({super.key});

  @override
  State<StudentsDataScreen> createState() => _StudentsDataScreenState();
}

class _StudentsDataScreenState extends State<StudentsDataScreen> {
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  Set<int> _expandedIndices = {}; // Track which cards are expanded

  @override
  void initState() {
    super.initState();
    _fetchStudentsData();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get UDISE code from app state
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appState.udiseCode ??
          "22010100101"; // Updated fallback to actual school UDISE

      print('🔍 DEBUG: Fetching students for UDISE Code: $udiseCode');
      print('🔍 DEBUG: App State UDISE: ${appState.udiseCode}');
      print('🔍 DEBUG: Logged in user: ${appState.loggedInUser}');

      final result = await ApiService.getStudentsByUdise(udiseCode);

      print('📡 DEBUG: Complete API Response: $result');
      print('✅ DEBUG: API Success: ${result['success']}');
      print('📄 DEBUG: API Data: ${result['data']}');

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          // Handle the API response format: {"status": true, "data": [...], "message": "..."}
          final responseData = result['data'];
          print('🗂️ DEBUG: Response Data Type: ${responseData.runtimeType}');
          print('🗂️ DEBUG: Response Data Content: $responseData');

          if (responseData['status'] == true && responseData['data'] != null) {
            final studentsList = responseData['data'] as List;
            print('👥 DEBUG: Students Found: ${studentsList.length}');
            print(
                '👥 DEBUG: First Student Sample: ${studentsList.isNotEmpty ? studentsList[0] : 'No students'}');

            _allStudents = List<Map<String, dynamic>>.from(studentsList
                .map((item) => Map<String, dynamic>.from(item as Map)));
            _filteredStudents = List<Map<String, dynamic>>.from(_allStudents);
            _isLoading = false;

            print(
                '✅ DEBUG: Students loaded successfully: ${_allStudents.length} students');
          } else {
            print(
                '❌ DEBUG: No students data - Status: ${responseData['status']}, Message: ${responseData['message']}');
            _allStudents = [];
            _filteredStudents = [];
            _errorMessage = responseData['message']?.toString() ??
                'इस UDISE कोड के लिए कोई छात्र डेटा नहीं मिला';
            _isLoading = false;
          }
        });
      } else {
        print(
            '❌ DEBUG: API call failed - Success: ${result['success']}, Data: ${result['data']}');
        setState(() {
          _errorMessage = result['data']?['message']?.toString() ??
              'इस UDISE कोड के लिए कोई छात्र डेटा नहीं मिला';
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

  void _filterStudents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final name = student['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    });
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';

    try {
      // Parse the date string and format it in a readable way
      DateTime dateTime =
          DateTime.parse(dateTimeString.replaceAll('GMT', '').trim());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString; // Return original string if parsing fails
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(color: AppTheme.darkGray),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPlantPhoto(Map<String, dynamic> student) async {
    try {
      // Extract filename from path
      String imagePath = student['plant_image']?.toString() ?? '';
      String filename = imagePath.split('/').last;

      final result = await ApiService.downloadImage(filename);

      if (result['success'] == true) {
        // Get Downloads directory
        Directory? downloadsDirectory;
        if (Platform.isAndroid) {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
        } else {
          downloadsDirectory = await getDownloadsDirectory();
        }

        if (downloadsDirectory != null && await downloadsDirectory.exists()) {
          // Create unique filename with student name
          String studentName =
              student['name']?.toString().replaceAll(' ', '_') ?? 'student';
          String uniqueFilename = '${studentName}_plant_photo_$filename';
          final file = File('${downloadsDirectory.path}/$uniqueFilename');
          await file.writeAsBytes(result['data'] as Uint8List);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${student['name']} की पौधे की फोटो Downloads फोल्डर में सेव हो गई'),
              backgroundColor: AppTheme.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Fallback to documents directory
          final directory = await getApplicationDocumentsDirectory();
          String studentName =
              student['name']?.toString().replaceAll(' ', '_') ?? 'student';
          String uniqueFilename = '${studentName}_plant_photo_$filename';
          final file = File('${directory.path}/$uniqueFilename');
          await file.writeAsBytes(result['data'] as Uint8List);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${student['name']} की पौधे की फोटो App फोल्डर में सेव हो गई'),
              backgroundColor: AppTheme.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('डाउनलोड में समस्या: ${result['data']['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('डाउनलोड एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _downloadCertificate(Map<String, dynamic> student) async {
    try {
      // Extract filename from path
      String imagePath = student['certificate']?.toString() ?? '';
      String filename = imagePath.split('/').last;

      final result = await ApiService.downloadImage(filename);

      if (result['success'] == true) {
        // Get Downloads directory
        Directory? downloadsDirectory;
        if (Platform.isAndroid) {
          downloadsDirectory = Directory('/storage/emulated/0/Download');
        } else {
          downloadsDirectory = await getDownloadsDirectory();
        }

        if (downloadsDirectory != null && await downloadsDirectory.exists()) {
          // Create unique filename with student name
          String studentName =
              student['name']?.toString().replaceAll(' ', '_') ?? 'student';
          String uniqueFilename = '${studentName}_certificate_$filename';
          final file = File('${downloadsDirectory.path}/$uniqueFilename');
          await file.writeAsBytes(result['data'] as Uint8List);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${student['name']} का सर्टिफिकेट Downloads फोल्डर में सेव हो गया'),
              backgroundColor: AppTheme.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Fallback to documents directory
          final directory = await getApplicationDocumentsDirectory();
          String studentName =
              student['name']?.toString().replaceAll(' ', '_') ?? 'student';
          String uniqueFilename = '${studentName}_certificate_$filename';
          final file = File('${directory.path}/$uniqueFilename');
          await file.writeAsBytes(result['data'] as Uint8List);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${student['name']} का सर्टिफिकेट App फोल्डर में सेव हो गया'),
              backgroundColor: AppTheme.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('डाउनलोड में समस्या: ${result['data']['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('डाउनलोड एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewImage(Map<String, dynamic> student, String imageType) async {
    try {
      // Extract filename from path
      String imagePath = imageType == 'plant'
          ? student['plant_image']?.toString() ?? ''
          : student['certificate']?.toString() ?? '';
      String filename = imagePath.split('/').last;

      // Show loading dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await ApiService.getImageByFilename(filename);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        // Show image in dialog
        _showImageDialog(student, result['data'] as Uint8List,
            imageType == 'plant' ? 'पौधे की फोटो' : 'सर्टिफिकेट', filename);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('इमेज लोड नहीं हो सकी: ${result['data']['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('इमेज लोड एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(Map<String, dynamic> student, Uint8List imageBytes,
      String title, String filename) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${student['name']} - $title',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              filename,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Image
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Download button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (title.contains('पौधे')) {
                          _downloadPlantPhoto(student);
                        } else {
                          _downloadCertificate(student);
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('डाउनलोड करें'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final udiseCode = appState.udiseCode ?? "N/A";

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('छात्र विवरण'),
            Text(
              'UDISE: $udiseCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentsData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'छात्र का नाम खोजें...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(height: 16),
                        Text('छात्र डेटा लोड हो रहा है...'),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchStudentsData,
                              child: const Text('पुनः प्रयास करें'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStudents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allStudents.isEmpty
                                      ? 'कोई छात्र डेटा नहीं मिला'
                                      : 'खोज के अनुकूल कोई छात्र नहीं मिला',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (_allStudents.isEmpty) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'इस UDISE कोड के लिए कोई पंजीकृत छात्र नहीं है',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStudents.length,
                            itemBuilder: (context, index) {
                              final student = _filteredStudents[index];
                              final isExpanded =
                                  _expandedIndices.contains(index);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    // Main card content - always visible
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedIndices.remove(index);
                                          } else {
                                            _expandedIndices.add(index);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  AppTheme.primaryGreen,
                                              radius: 25,
                                              child: Text(
                                                (student['name']?.toString() ??
                                                        'N')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                student['name']?.toString() ??
                                                    'अज्ञात',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Expanded content - only visible when expanded
                                    if (isExpanded) ...[
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('स्कूल',
                                                student['school_name']),
                                            _buildDetailRow(
                                                'कक्षा', student['class']),
                                            _buildDetailRow(
                                                'मोबाइल', student['mobile']),
                                            _buildDetailRow('पेड़ का नाम',
                                                student['name_of_tree']),
                                            _buildDetailRow('UDISE कोड',
                                                student['udise_code']),
                                            _buildDetailRow(
                                                'पंजीकरण दिनांक',
                                                _formatDate(student['date_time']
                                                    ?.toString())),
                                            const SizedBox(height: 16),

                                            // View buttons only
                                            Column(
                                              children: [
                                                // Plant Image view button
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _viewImage(
                                                        student, 'plant'),
                                                    icon: const Icon(
                                                        Icons.visibility,
                                                        size: 18),
                                                    label: const Text(
                                                        'पौधे की फोटो देखें'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppTheme.green,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Certificate view button
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () => _viewImage(
                                                        student, 'certificate'),
                                                    icon: const Icon(
                                                        Icons.visibility,
                                                        size: 18),
                                                    label: const Text(
                                                        'सर्टिफिकेट देखें'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          AppTheme.blue,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
