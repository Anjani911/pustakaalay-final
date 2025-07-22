import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class NewPhotoUploadScreen extends StatelessWidget {
  const NewPhotoUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('नई फोटो अपलोड'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => appState.goBackToHome(),
        ),
      ),
      body: const Center(
        child: Text(
          'नई फोटो अपलोड स्क्रीन\n(जल्द ही उपलब्ध)',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
