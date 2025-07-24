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
  Set<int> _expandedIndices = {}; // Track which cards are expanded
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

  // Photo update methods
  bool _isPhotoUpdateRequired(Map<String, dynamic> student) {
    try {
      // Check if there's a last photo update date, otherwise use registration date
      final lastPhotoUpdateString = student['last_photo_update']?.toString();
      final dateTimeString = lastPhotoUpdateString ?? student['date_time']?.toString();
      
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
      if (lastPhotoUpdateString == null || lastPhotoUpdateString.isEmpty) return false;

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
      final dateTimeString = lastPhotoUpdateString ?? student['date_time']?.toString();
      
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

  Future<void> _pickAndUploadPhoto(Map<String, dynamic> student, ImageSource source) async {
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

  Future<void> _uploadStudentPhoto(Map<String, dynamic> student, File imageFile) async {
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
            _allStudents[studentIndex]['last_photo_update'] = DateTime.now().toIso8601String();
            _studentsNeedingPhotoUpdate = _allStudents.where(_isPhotoUpdateRequired).length;
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
        final studentsData = result['data'];
        if (studentsData is List) {
          students = List<Map<String, dynamic>>.from(studentsData);
        } else {
          students = [];
        }
      } else {
        throw Exception(
            result['data']?['message'] ?? 'Failed to fetch students data');
      }
      print('API Response - Students count: ${students.length}');

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
          final parentName =
              student['parent_name']?.toString().toLowerCase() ?? '';
          final className =
              student['class_name']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();

          return studentName.contains(searchQuery) ||
              studentId.contains(searchQuery) ||
              parentName.contains(searchQuery) ||
              className.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppStateProvider>(context);
    final udiseCode = appState.udiseCode ?? "N/A";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('छात्र डेटा'),
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
                              final isPhotoLocked = _isPhotoUpdateLocked(student);
                              final daysSinceLastUpdate =
                                  _getDaysSinceLastPhotoUpdate(student);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: needsPhotoUpdate
                                      ? const BorderSide(
                                          color: Colors.red, width: 2)
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
                                      title: Text(
                                        student['student_name']?.toString() ??
                                            'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'ID: ${student['student_id']?.toString() ?? 'N/A'}'),
                                          Text(
                                              'कक्षा: ${student['class_name']?.toString() ?? 'N/A'}'),
                                          if (needsPhotoUpdate)
                                            Text(
                                              isPhotoLocked
                                                  ? 'फोटो अपडेट लॉक है (${7 - daysSinceLastUpdate} दिन बाकी)'
                                                  : 'फोटो अपडेट आवश्यक ($daysSinceLastUpdate दिन)',
                                              style: TextStyle(
                                                color: isPhotoLocked ? Colors.orange : Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (needsPhotoUpdate)
                                            IconButton(
                                              icon: Icon(
                                                isPhotoLocked ? Icons.lock : Icons.camera_alt,
                                                color: isPhotoLocked ? Colors.orange : Colors.red,
                                              ),
                                              onPressed: isPhotoLocked 
                                                  ? null 
                                                  : () => _showPhotoUpdateDialog(student),
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
                                            _buildDetailRow('अभिभावक का नाम',
                                                student['parent_name']),
                                            _buildDetailRow('फोन नंबर',
                                                student['phone_number']),
                                            _buildDetailRow(
                                                'ईमेल', student['email']),
                                            _buildDetailRow(
                                                'पता', student['address']),
                                            _buildDetailRow('जन्म तिथि',
                                                student['date_of_birth']),
                                            _buildDetailRow(
                                                'लिंग', student['gender']),
                                            _buildDetailRow('पंजीकरण तिथि',
                                                student['date_time']),
                                            _buildDetailRow(
                                                'सेक्शन', student['section']),
                                            _buildDetailRow('रोल नंबर',
                                                student['roll_number']),
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
                                                          color: isPhotoLocked ? Colors.orange : Colors.red,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: isPhotoLocked 
                                                          ? null 
                                                          : () => _showPhotoUpdateDialog(student),
                                                      child: Text(
                                                        isPhotoLocked ? 'लॉक है' : 'अपडेट करें',
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
}
