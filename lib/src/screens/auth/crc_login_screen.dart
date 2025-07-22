import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';

class CRCLoginScreen extends StatefulWidget {
  const CRCLoginScreen({super.key});

  @override
  State<CRCLoginScreen> createState() => _CRCLoginScreenState();
}

class _CRCLoginScreenState extends State<CRCLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call API login
        final result = await ApiService.supervisorLogin(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (result['success'] == true) {
          // Login successful
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          
          // Debug: Print full response for verification
          print('Full login response: ${result['data']}');
          
          // Extract UDISE code from response if available
          String? udiseCode;
          // The response structure is: result['data']['data']['udise_code']
          if (result['data'] != null && 
              result['data']['data'] != null && 
              result['data']['data']['udise_code'] != null) {
            udiseCode = result['data']['data']['udise_code'].toString();
            print('Supervisor UDISE code extracted from login: $udiseCode');
          } else {
            print('No UDISE code found in login response');
            print('Response data keys: ${result['data']?.keys}');
            print('Inner data keys: ${result['data']?['data']?.keys}');
          }
          
          appState.handleLoginSuccess(
            UserType.crc, 
            username: _usernameController.text.trim(),
            udiseCode: udiseCode,
          );
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('लॉगिन सफल रहा!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Login failed
          String errorMessage = 'लॉगिन असफल';
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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('सुपरवाइजर लॉगिन'),
        backgroundColor: AppTheme.blue,
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
                const SizedBox(height: 40),
                
                // Logo and title
                const Icon(
                  Icons.supervisor_account,
                  size: 80,
                  color: AppTheme.blue,
                ),
                const SizedBox(height: 20),
                
                Text(
                  'हरिहर पाठशाला में स्वागत',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'कृपया अपनी लॉगिन जानकारी दर्ज करें',
                  style: TextStyle(
                    color: AppTheme.darkGray,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Username field
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'सुपरवाइजर आईडी',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            hintText: 'अपना सुपरवाइजर आईडी दर्ज करें',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया सुपरवाइजर आईडी दर्ज करें';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Password field
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'पासवर्ड',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'अपना पासवर्ड दर्ज करें',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'कृपया पासवर्ड दर्ज करें';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Login button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'लॉगिन करें',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.blue.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'लॉगिन में समस्या? कृपया जिला शिक्षा अधिकारी से संपर्क करें।',
                    style: TextStyle(
                      color: AppTheme.darkGray,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
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
