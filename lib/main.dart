import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/home/home_screen.dart';
import 'src/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: NetflixCloneApp()));
}

class NetflixCloneApp extends StatelessWidget {
  const NetflixCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Netflix',
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}
