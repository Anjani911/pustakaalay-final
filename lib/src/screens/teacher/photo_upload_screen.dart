import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _childPlantImage; // बच्चे और पौधे की फोटो
  File? _certificateImage; // सर्टिफिकेट की फोटो
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _schoolController = TextEditingController();
  final _classController = TextEditingController();
  final _plantNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _employeeIdController = TextEditingController();
  bool _isUploading = false;
  String? _selectedClass; // Selected class for dropdown

  @override
  void dispose() {
    _studentNameController.dispose();
    _schoolController.dispose();
    _classController.dispose();
    _plantNameController.dispose();
    _mobileController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, String imageType) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (imageType == 'child_plant') {
            _childPlantImage = File(image.path);
          } else if (imageType == 'certificate') {
            _certificateImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('फोटो सेलेक्ट करने में त्रुटि: $e')),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_formKey.currentState!.validate() &&
        _childPlantImage != null &&
        _certificateImage != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        // Get UDISE code from app state
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final String udiseCode =
            appState.udiseCode ?? '1234'; // Fallback to 1234 if not available

        // Call API to register student with actual file objects
        final result = await ApiService.registerStudent(
          name: _studentNameController.text.trim(),
          schoolName: _schoolController.text.trim(),
          className: _classController.text.trim(),
          mobile: _mobileController.text.trim(),
          nameOfTree: _plantNameController.text.trim(),
          plantImage: _childPlantImage!,
          certificateImage: _certificateImage!,
          udiseCode: udiseCode,
          employeeId: _employeeIdController.text
              .trim(), // Always send as string (empty if not provided)
        );

        if (!mounted) return;

        if (result['success'] == true) {
          // Registration successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('छात्र पंजीकरण सफल रहा!'),
              backgroundColor: AppTheme.green,
            ),
          );

          // Reset form
          setState(() {
            _childPlantImage = null;
            _certificateImage = null;
            _selectedClass = null; // Reset selected class
            _isUploading = false;
          });
          _formKey.currentState!.reset();
          _studentNameController.clear();
          _schoolController.clear();
          _classController.clear();
          _plantNameController.clear();
          _mobileController.clear();
          _employeeIdController.clear();
        } else {
          // Registration failed
          String errorMessage = 'पंजीकरण असफल';
          if (result['data'] != null && result['data']['message'] != null) {
            errorMessage = result['data']['message'].toString();
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('नेटवर्क एरर: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isUploading = false;
      });
    } else if (_childPlantImage == null || _certificateImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया दोनों फोटो सेलेक्ट करें')),
      );
    }
  }

  void _showImageSourceDialog(String imageType) {
    final String title = imageType == 'child_plant'
        ? 'बच्चे और पौधे की फोटो'
        : 'सर्टिफिकेट की फोटो';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$title कैसे लें?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('कैमरा से फोटो लें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, imageType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('गैलरी से चुनें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, imageType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('फोटो अपलोड'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBack(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions card
                const Card(
                  color: AppTheme.lightBlue,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppTheme.blue,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'फोटो अपलोड निर्देश',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• पहली फोटो: छात्र, पेड़ और शिक्षक तीनों दिखने चाहिए\n'
                          '• दूसरी फोटो: पेड़ लगाने का सर्टिफिकेट\n'
                          '• दोनों फोटो साफ और स्पष्ट होनी चाहिए\n'
                          '• उचित रोशनी में फोटो लें',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.darkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo selection areas
                // 1. Child and Plant Photo
                const Text(
                  '1. बच्चे और पौधे की फोटो',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImageSourceDialog('child_plant'),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          _childPlantImage != null ? null : AppTheme.lightGreen,
                    ),
                    child: _childPlantImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _childPlantImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: AppTheme.primaryGreen,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'बच्चे और पौधे की फोटो लें',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Certificate Photo
                const Text(
                  '2. सर्टिफिकेट की फोटो',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showImageSourceDialog('certificate'),
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.blue,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          _certificateImage != null ? null : AppTheme.lightBlue,
                    ),
                    child: _certificateImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _certificateImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.description,
                                size: 50,
                                color: AppTheme.blue,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'सर्टिफिकेट की फोटो लें',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Student details form
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'छात्र की जानकारी',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _studentNameController,
                          decoration: const InputDecoration(
                            labelText: 'छात्र का नाम',
                            hintText: 'छात्र का पूरा नाम दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया छात्र का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _schoolController,
                          decoration: const InputDecoration(
                            labelText: 'स्कूल का नाम',
                            hintText: 'स्कूल का पूरा नाम दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया स्कूल का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: 'कक्षा',
                            hintText: 'कक्षा चुनें (1-12)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          items: List.generate(12, (index) {
                            final classNumber = index + 1;
                            return DropdownMenuItem<String>(
                              value: classNumber.toString(),
                              child: Text('कक्षा $classNumber'),
                            );
                          }),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedClass = newValue;
                              // Update the controller for API compatibility
                              _classController.text = newValue ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया कक्षा चुनें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _plantNameController,
                          decoration: const InputDecoration(
                            labelText: 'पेड़ का नाम',
                            hintText: 'उदाहरण: आम, नीम, पीपल',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.park),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया पेड़ का नाम दर्ज करें';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'मोबाइल नंबर',
                            hintText: '10 अंकों का मोबाइल नंबर दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                            counterText: '', // Hide character counter
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया मोबाइल नंबर दर्ज करें';
                            }
                            if (value.length != 10) {
                              return 'मोबाइल नंबर 10 अंकों का होना चाहिए';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'केवल अंक दर्ज करें';
                            }
                            if (value.startsWith('0') ||
                                value.startsWith('1') ||
                                value.startsWith('2') ||
                                value.startsWith('3') ||
                                value.startsWith('4') ||
                                value.startsWith('5')) {
                              return 'मोबाइल नंबर 6-9 से शुरू होना चाहिए';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _employeeIdController,
                          decoration: const InputDecoration(
                            labelText: 'कर्मचारी ID',
                            hintText: 'कर्मचारी की ID दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया Employee ID दर्ज करें';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Upload button
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadPhoto,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      _isUploading
                          ? 'पंजीकरण हो रहा है...'
                          : 'छात्र पंजीकरण करें',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
