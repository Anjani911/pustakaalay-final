import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/app_state_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/navigation/app_navigator.dart';

void main() {
  runApp(const HariHarPathshalaApp());
}

class HariHarPathshalaApp extends StatelessWidget {
  const HariHarPathshalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'एक पेड़ माँ के नाम 2.0',
            theme: themeProvider.theme,
            home: const AppNavigator(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
