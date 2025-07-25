import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/app_state_provider.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  String _errorMessage = '';
  final Set<int> _expandedIndices = {}; // Track which cards are expanded
  int _studentsNeedingPhotoUpdate = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchStudentsData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStudents(_searchController.text);
  }

  // Method to format date for display
  String _formatDate(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);

      // Format as DD/MM/YYYY
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'तारीख ज्ञात नहीं';
    }
  }

  // Method to format date time for display with time
  String _formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);

      // Format as DD/MM/YYYY HH:MM
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting datetime: $e');
      return 'समय ज्ञात नहीं';
    }
  }

  // Photo update methods
  bool _isPhotoUpdateRequired(Map<String, dynamic> student) {
    try {
      // Check if there's a last photo update date, otherwise use registration date
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final dateTimeString =
          lastPhotoUpdateString ?? student['date_time']?.toString();

      if (dateTimeString == null || dateTimeString.isEmpty) return false;

      final lastUpdateDate = DateTime.parse(dateTimeString);
      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(lastUpdateDate).inDays;

      // Show red icon only after 7+ days since last photo update
      return daysDifference >= 7;
    } catch (e) {
      print('Error calculating photo update requirement: $e');
      return false;
    }
  }

  bool _isPhotoUpdateLocked(Map<String, dynamic> student) {
    try {
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      if (lastPhotoUpdateString == null || lastPhotoUpdateString.isEmpty) {
        return false;
      }

      final lastUpdateDate = DateTime.parse(lastPhotoUpdateString);
      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(lastUpdateDate).inDays;

      // Lock photo update for 7 days after last update
      return daysDifference < 7;
    } catch (e) {
      print('Error calculating photo update lock: $e');
      return false;
    }
  }

  int _getDaysSinceLastPhotoUpdate(Map<String, dynamic> student) {
    try {
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final dateTimeString =
          lastPhotoUpdateString ?? student['date_time']?.toString();

      if (dateTimeString == null || dateTimeString.isEmpty) return 0;

      final lastUpdateDate = DateTime.parse(dateTimeString);
      final currentDate = DateTime.now();
      return currentDate.difference(lastUpdateDate).inDays;
    } catch (e) {
      print('Error calculating days since last photo update: $e');
      return 0;
    }
  }

  int _getDaysSinceRegistration(Map<String, dynamic> student) {
    try {
      final dateTimeString = student['date_time']?.toString();
      if (dateTimeString == null || dateTimeString.isEmpty) return 0;

      final registrationDate = DateTime.parse(dateTimeString);
      final currentDate = DateTime.now();
      return currentDate.difference(registrationDate).inDays;
    } catch (e) {
      print('Error calculating days since registration: $e');
      return 0;
    }
  }

  // Check if student is newly registered (within last 7 days)
  bool _isNewlyRegistered(Map<String, dynamic> student) {
    try {
      final dateTimeString = student['date_time']?.toString();
      if (dateTimeString == null || dateTimeString.isEmpty) return false;

      final registrationDate = DateTime.parse(dateTimeString);
      final currentDate = DateTime.now();
      final daysDifference = currentDate.difference(registrationDate).inDays;

      return daysDifference <= 7; // Show as "new" for 7 days
    } catch (e) {
      print('Error checking if newly registered: $e');
      return false;
    }
  }

  void _showPhotoUpdateDialog(Map<String, dynamic> student) {
    final isLocked = _isPhotoUpdateLocked(student);
    final daysSinceLastUpdate = _getDaysSinceLastPhotoUpdate(student);
    final daysUntilUnlock = isLocked ? (7 - daysSinceLastUpdate) : 0;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('फोटो अपडेट करें - ${student['student_name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('छात्र ID: ${student['student_id']}'),
              const SizedBox(height: 8),
              if (isLocked) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'फोटो अपडेट $daysUntilUnlock दिन बाद उपलब्ध होगा',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('अंतिम फोटो अपडेट के बाद से दिन: $daysSinceLastUpdate'),
                const SizedBox(height: 16),
                const Text('फोटो अपडेट करना आवश्यक है'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('रद्द करें'),
            ),
            if (!isLocked) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('कैमरा'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadPhoto(student, ImageSource.camera);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('गैलरी'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickAndUploadPhoto(student, ImageSource.gallery);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(
      Map<String, dynamic> student, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadStudentPhoto(student, File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('फोटो सेलेक्ट करने में त्रुटि: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadStudentPhoto(
      Map<String, dynamic> student, File imageFile) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('फोटो अपलोड हो रही है...'),
            ],
          ),
        );
      },
    );

    try {
      // Call API to update student photo
      final result = await ApiService.updateStudentPhoto(
        studentId: student['student_id'].toString(),
        photoFile: imageFile,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (result['success'] == true) {
        // Update the student data locally
        final studentIndex = _allStudents.indexWhere(
          (s) => s['student_id'] == student['student_id'],
        );

        if (studentIndex != -1) {
          setState(() {
            _allStudents[studentIndex]['last_photo_update'] =
                DateTime.now().toIso8601String();
            _studentsNeedingPhotoUpdate =
                _allStudents.where(_isPhotoUpdateRequired).length;
          });
          _filterStudents(_searchController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('फोटो सफलतापूर्वक अपडेट हो गई!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String errorMessage = 'फोटो अपडेट असफल';
        final data = result['data'];
        if (data != null && data['message'] != null) {
          errorMessage = data['message'].toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('नेटवर्क एरर: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhotoUpdateSummary() {
    final studentsNeedingUpdate =
        _allStudents.where(_isPhotoUpdateRequired).toList();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('फोटो अपडेट की आवश्यकता वाले छात्र'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${studentsNeedingUpdate.length} छात्रों को फोटो अपडेट की आवश्यकता है'),
                const SizedBox(height: 16),
                if (studentsNeedingUpdate.isNotEmpty) ...[
                  const Text('छात्र:'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: studentsNeedingUpdate.length,
                      itemBuilder: (context, index) {
                        final student = studentsNeedingUpdate[index];
                        final days = _getDaysSinceRegistration(student);
                        return ListTile(
                          leading:
                              const Icon(Icons.camera_alt, color: Colors.red),
                          title: Text(
                              student['student_name']?.toString() ?? 'N/A'),
                          subtitle:
                              Text('ID: ${student['student_id']} • $days दिन'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _showPhotoUpdateDialog(student);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('बंद करें'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchStudentsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<Map<String, dynamic>> students;

      // Use API data
      final appStateProvider =
          Provider.of<AppStateProvider>(context, listen: false);
      final udiseCode = appStateProvider.udiseCode;

      if (udiseCode == null || udiseCode.isEmpty) {
        throw Exception('UDISE code not found. Please login again.');
      }

      final result = await ApiService.getStudentsByUdise(udiseCode);
      if (result['success'] == true && result['data'] != null) {
        final responseData = result['data'];

        // Handle different response structures
        List<dynamic> studentsData = [];
        if (responseData is Map<String, dynamic>) {
          // If response has nested data structure
          if (responseData.containsKey('data')) {
            final nestedData = responseData['data'];
            if (nestedData is List) {
              studentsData = nestedData;
            }
          }
        } else if (responseData is List) {
          // If response is directly a list
          studentsData = responseData;
        }

        print('Students data count: ${studentsData.length}');
        print(
            'Sample student data: ${studentsData.isNotEmpty ? studentsData.first : 'No data'}');

        // Debug: Check if employee_id field is available
        if (studentsData.isNotEmpty) {
          final sampleStudent = studentsData.first;
          print('Available fields in student data: ${sampleStudent.keys}');
          print('Employee ID field value: ${sampleStudent['employee_id']}');

          // Check all possible employee ID field names
          print('emp_id: ${sampleStudent['emp_id']}');
          print('employee_number: ${sampleStudent['employee_number']}');
          print('teacher_id: ${sampleStudent['teacher_id']}');
          print('empId: ${sampleStudent['empId']}');
          print('employeeId: ${sampleStudent['employeeId']}');

          // Check if the latest student (Jatin) has employee_id
          final latestStudent = studentsData.firstWhere(
            (student) =>
                student['name']?.toString().toLowerCase().contains('jatin') ==
                true,
            orElse: () => null,
          );

          if (latestStudent != null) {
            print('=== JATIN\'S DATA DEBUG ===');
            print('Jatin full data: $latestStudent');
            print('Jatin employee_id: ${latestStudent['employee_id']}');
            print('Jatin emp_id: ${latestStudent['emp_id']}');
            print('Jatin all keys: ${latestStudent.keys}');
          }
        }

        // Map API field names to expected field names
        students = studentsData
            .map((studentData) {
              if (studentData is Map<String, dynamic>) {
                return {
                  'student_id': studentData['mobile']?.toString() ??
                      studentData['student_id']?.toString() ??
                      'N/A',
                  'student_name': studentData['name']?.toString() ??
                      studentData['student_name']?.toString() ??
                      'N/A',
                  'class_name': studentData['class']?.toString() ??
                      studentData['class_name']?.toString() ??
                      'N/A',
                  'phone_number': studentData['mobile']?.toString() ??
                      studentData['phone_number']?.toString() ??
                      'N/A',
                  'employee_id': studentData['employee_id']?.toString() ??
                      studentData['emp_id']?.toString() ??
                      studentData['employeeId']?.toString() ??
                      studentData['empId']?.toString() ??
                      studentData['teacher_id']?.toString() ??
                      'N/A',
                  'date_time': studentData['date_time']?.toString() ?? 'N/A',
                  'udise_code':
                      studentData['udise_code']?.toString() ?? udiseCode,
                  'school_name':
                      studentData['school_name']?.toString() ?? 'N/A',
                  'name_of_tree':
                      studentData['name_of_tree']?.toString() ?? 'N/A',
                  'plant_image': studentData['plant_image']?.toString() ?? '',
                  'certificate': studentData['certificate']?.toString() ?? '',
                  'verified': studentData['verified']?.toString() ?? 'false',
                  'last_photo_update':
                      studentData['last_photo_update']?.toString() ??
                          studentData['date_time']?.toString(),
                };
              }
              return <String, dynamic>{};
            })
            .where((student) => student.isNotEmpty)
            .toList();
      } else {
        throw Exception(
            result['data']?['message'] ?? 'Failed to fetch students data');
      }
      print('API Response - Students count: ${students.length}');

      // Sort students by registration date - newest first
      students.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date_time']?.toString() ?? '');
          final dateB = DateTime.parse(b['date_time']?.toString() ?? '');
          return dateB.compareTo(dateA); // Newest first (descending order)
        } catch (e) {
          return 0; // Keep original order if date parsing fails
        }
      });

      setState(() {
        _allStudents = students;
        _filteredStudents = List.from(students);
        _studentsNeedingPhotoUpdate =
            _allStudents.where(_isPhotoUpdateRequired).length;
        _isLoading = false;
      });

      _filterStudents(_searchController.text);
    } catch (e) {
      print('Error fetching students data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _allStudents = [];
        _filteredStudents = [];
        _studentsNeedingPhotoUpdate = 0;
      });
    }
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents.where((student) {
          final studentName =
              student['student_name']?.toString().toLowerCase() ?? '';
          final studentId =
              student['student_id']?.toString().toLowerCase() ?? '';
          final phoneNumber =
              student['phone_number']?.toString().toLowerCase() ?? '';
          final className =
              student['class_name']?.toString().toLowerCase() ?? '';
          final schoolName =
              student['school_name']?.toString().toLowerCase() ?? '';
          final employeeId =
              student['employee_id']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return studentName.contains(searchQuery) ||
              studentId.contains(searchQuery) ||
              phoneNumber.contains(searchQuery) ||
              className.contains(searchQuery) ||
              schoolName.contains(searchQuery) ||
              employeeId.contains(searchQuery);
        }).toList();
      }

      // Always sort filtered results by registration date - newest first
      _filteredStudents.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['date_time']?.toString() ?? '');
          final dateB = DateTime.parse(b['date_time']?.toString() ?? '');
          return dateB.compareTo(dateA); // Newest first (descending order)
        } catch (e) {
          return 0; // Keep original order if date parsing fails
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final udiseCode = appState.udiseCode ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('छात्र डेटा'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'नवीनतम पहले',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'UDISE: $udiseCode',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: theme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
        actions: [
          if (_studentsNeedingPhotoUpdate > 0) ...[
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.camera_alt),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_studentsNeedingPhotoUpdate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                _showPhotoUpdateSummary();
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentsData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'छात्रों को खोजें...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
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
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'डेटा लोड करने में त्रुटि',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _errorMessage,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('पुनः प्रयास'),
                              onPressed: _fetchStudentsData,
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
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _allStudents.isEmpty
                                      ? 'कोई छात्र नहीं मिला'
                                      : 'आपकी खोज से कोई छात्र मेल नहीं खाता',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                if (_allStudents.isEmpty) ...[
                                  const Text(
                                      'डेटा रिफ्रेश करने का प्रयास करें'),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('रिफ्रेश करें'),
                                    onPressed: _fetchStudentsData,
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
                              final needsPhotoUpdate =
                                  _isPhotoUpdateRequired(student);
                              final isPhotoLocked =
                                  _isPhotoUpdateLocked(student);
                              final daysSinceLastUpdate =
                                  _getDaysSinceLastPhotoUpdate(student);
                              final isNewlyRegistered =
                                  _isNewlyRegistered(student);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: needsPhotoUpdate
                                      ? const BorderSide(
                                          color: Colors.red, width: 2)
                                      : isNewlyRegistered
                                          ? const BorderSide(
                                              color: Colors.green, width: 2)
                                          : BorderSide.none,
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: theme.primaryColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              (student['student_name']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true)
                                                  ? student['student_name']!
                                                      .toString()[0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: theme.primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (needsPhotoUpdate)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Student name with NEW badge
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  student['student_name']
                                                          ?.toString() ??
                                                      'N/A',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              if (isNewlyRegistered) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: const Text(
                                                    'NEW',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                              'ID: ${student['student_id']?.toString() ?? 'N/A'}'),
                                          Text(
                                              'कक्षा: ${student['class_name']?.toString() ?? 'N/A'}'),
                                          const SizedBox(height: 8),
                                          // Upload Photo Button - only show when needed
                                          if (_isPhotoUpdateRequired(student) &&
                                              !_isPhotoUpdateLocked(student))
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  _showPhotoUpdateDialog(
                                                      student);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.red[600],
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  elevation: 2,
                                                ),
                                                icon: const Icon(
                                                  Icons.camera_alt,
                                                  size: 18,
                                                ),
                                                label: const Text(
                                                  'फोटो अपडेट करें',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // Last upload info
                                          if (student['date_time']
                                                  ?.toString()
                                                  .isNotEmpty ==
                                              true)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'पिछला अपलोड: ${_formatDate(student['date_time']?.toString() ?? '')}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          if (needsPhotoUpdate)
                                            Text(
                                              isPhotoLocked
                                                  ? 'फोटो अपडेट लॉक है (${7 - daysSinceLastUpdate} दिन बाकी)'
                                                  : 'फोटो अपडेट आवश्यक ($daysSinceLastUpdate दिन)',
                                              style: TextStyle(
                                                color: isPhotoLocked
                                                    ? Colors.orange
                                                    : Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Upload status indicator
                                          if (ApiService.canUploadNow(
                                              student['date_time']
                                                      ?.toString() ??
                                                  ''))
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green[600],
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            )
                                          else
                                            Builder(
                                              builder: (context) {
                                                final remainingDays = ApiService
                                                    .getRemainingDaysForUpload(
                                                        student['last_photo_update']
                                                                ?.toString() ??
                                                            student['date_time']
                                                                ?.toString() ??
                                                            '');
                                                if (remainingDays > 0) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[600],
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.blue
                                                              .withOpacity(0.3),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      '$remainingDays',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          const SizedBox(width: 8),
                                          // Verification status
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  student['verified'] == 'true'
                                                      ? Colors.green[100]
                                                      : Colors.red[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              student['verified'] == 'true'
                                                  ? 'सत्यापित'
                                                  : 'असत्यापित',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: student['verified'] ==
                                                        'true'
                                                    ? Colors.green[800]
                                                    : Colors.red[800],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (needsPhotoUpdate)
                                            IconButton(
                                              icon: Icon(
                                                isPhotoLocked
                                                    ? Icons.lock
                                                    : Icons.camera_alt,
                                                color: isPhotoLocked
                                                    ? Colors.orange
                                                    : Colors.red,
                                              ),
                                              onPressed: isPhotoLocked
                                                  ? null
                                                  : () =>
                                                      _showPhotoUpdateDialog(
                                                          student),
                                              tooltip: isPhotoLocked
                                                  ? 'फोटो अपडेट लॉक है'
                                                  : 'फोटो अपडेट करें',
                                            ),
                                          Icon(
                                            isExpanded
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedIndices.remove(index);
                                          } else {
                                            _expandedIndices.add(index);
                                          }
                                        });
                                      },
                                    ),
                                    if (isExpanded) ...[
                                      const Divider(height: 1),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildDetailRow('Employee ID',
                                                student['employee_id']),
                                            _buildDetailRow('मोबाइल नंबर',
                                                student['phone_number']),
                                            _buildDetailRow('स्कूल का नाम',
                                                student['school_name']),
                                            _buildDetailRow('UDISE कोड',
                                                student['udise_code']),
                                            _buildDetailRow('पेड़ का नाम',
                                                student['name_of_tree']),
                                            _buildDetailRow('पंजीकरण तिथि',
                                                student['date_time']),
                                            _buildDetailRow(
                                                'वेरिफिकेशन स्टेटस',
                                                student['verified'] == 'true'
                                                    ? 'सत्यापित'
                                                    : 'असत्यापित'),
                                            if (student['plant_image']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                              _buildPhotoRow('पौधे की फोटो',
                                                  student['plant_image']),
                                            if (student['certificate']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                              _buildPhotoRow('सर्टिफिकेट',
                                                  student['certificate']),
                                            if (needsPhotoUpdate) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.red
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.red
                                                          .withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.warning,
                                                        color: Colors.red,
                                                        size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        isPhotoLocked
                                                            ? 'फोटो अपडेट लॉक है - ${7 - daysSinceLastUpdate} दिन बाकी'
                                                            : 'फोटो अपडेट आवश्यक - अंतिम अपडेट के $daysSinceLastUpdate दिन बाद',
                                                        style: TextStyle(
                                                          color: isPhotoLocked
                                                              ? Colors.orange
                                                              : Colors.red,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: isPhotoLocked
                                                          ? null
                                                          : () =>
                                                              _showPhotoUpdateDialog(
                                                                  student),
                                                      child: Text(
                                                        isPhotoLocked
                                                            ? 'लॉक है'
                                                            : 'अपडेट करें',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(String label, dynamic imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'उपलब्ध',
                  style: TextStyle(fontWeight: FontWeight.w400),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewPhoto(imageUrl?.toString() ?? ''),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('देखें'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewPhoto(String imageUrl) {
    if (imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('फोटो उपलब्ध नहीं है'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add base URL if relative path
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http')) {
      fullImageUrl = '${ApiService.baseUrl}/$imageUrl';
    }

    // Determine title based on image type
    String title = 'फोटो देखें';
    if (imageUrl.contains('plant')) {
      title = '🌱 पौधे की फोटो';
    } else if (imageUrl.contains('certificate')) {
      title = '📜 सर्टिफिकेट';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with title and close button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        imageUrl.contains('plant')
                            ? Icons.local_florist
                            : Icons.description,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Image container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          fullImageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 3,
                                    color: Colors.green[600],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'फोटो लोड हो रही है...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (loadingProgress.expectedTotalBytes !=
                                      null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${((loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!) * 100).toInt()}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 60,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'फोटो लोड नहीं हो सकी',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'नेटवर्क कनेक्शन या फाइल की जांच करें',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('बंद करें'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Zoom instruction
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.touch_app,
                                color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'ज़ूम करने के लिए पिंच करें',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Full screen button
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('फुल स्क्रीन के लिए ज़ूम करें'),
                              backgroundColor: Colors.green[600],
                            ),
                          );
                        },
                        icon: const Icon(Icons.fullscreen, size: 18),
                        label: const Text('फुल स्क्रीन'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
