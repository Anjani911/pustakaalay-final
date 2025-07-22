import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _classController = TextEditingController();
  final _schoolController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _classController.dispose();
    _schoolController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('फोटो सेलेक्ट करने में त्रुटि: $e')),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      setState(() {
        _isUploading = true;
      });

      // Simulate upload process
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('फोटो सफलतापूर्वक अपलोड हो गई!'),
          backgroundColor: AppTheme.green,
        ),
      );

      // Reset form
      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });
      _formKey.currentState!.reset();
      _studentNameController.clear();
      _classController.clear();
      _schoolController.clear();
      _remarksController.clear();
    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('कृपया पहले फोटो सेलेक्ट करें')),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('फोटो कैसे लें?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('कैमरा से फोटो लें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('गैलरी से चुनें'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
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
                Card(
                  color: AppTheme.lightBlue,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info,
                          color: AppTheme.blue,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'फोटो अपलोड निर्देश',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• छात्र, पेड़ और शिक्षक तीनों फोटो में दिखने चाहिए\n'
                          '• फोटो साफ और स्पष्ट होनी चाहिए\n'
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

                // Photo selection area
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryGreen,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: _selectedImage != null ? null : AppTheme.lightGreen,
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 60,
                                color: AppTheme.primaryGreen,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'फोटो सेलेक्ट करने के लिए यहाँ टैप करें',
                                style: TextStyle(
                                  fontSize: 16,
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
                          controller: _classController,
                          decoration: const InputDecoration(
                            labelText: 'कक्षा',
                            hintText: 'उदाहरण: कक्षा 5',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.class_),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया कक्षा दर्ज करें';
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

                        TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'टिप्पणी (वैकल्पिक)',
                            hintText: 'कोई अतिरिक्त जानकारी...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
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
                      _isUploading ? 'अपलोड हो रहा है...' : 'फोटो अपलोड करें',
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
