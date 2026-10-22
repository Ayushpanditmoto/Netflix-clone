import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'src/features/player/playback_shell.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
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
      home: const PlaybackShell(),
    );
  }
}
