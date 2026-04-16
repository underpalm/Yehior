import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'screens/home_screen.dart';
import 'services/openai_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatProvider(
        openai: OpenAIService(
          apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
        ),
        storage: StorageService(),
      ),
      child: const YehiorApp(),
    ),
  );
}

class YehiorApp extends StatelessWidget {
  const YehiorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yehior',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
      ),
      home: const HomeScreen(),
    );
  }
}
