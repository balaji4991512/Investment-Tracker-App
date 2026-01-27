import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/cred_theme.dart';
import 'screens/home_screen.dart';
import 'services/json_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI for dark theme
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0D0D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Initialize/reload SharedPreferences to ensure fresh data on restart
  await JsonStorageService.reloadPrefs();
  
  // Restore from backup if needed (web)
  if (kIsWeb) {
    final storage = JsonStorageService();
    final backup = await storage.getBackupString();
    print('🔎 Backup present: ${backup != null} len=${backup?.length ?? 0}');
    await storage.restoreFromBackupIfNeeded();
  }
  
  // Load environment variables (fail gracefully if .env doesn't exist)
  try {
    await dotenv.load(fileName: "assets/.env");
    print('✅ .env file loaded successfully');
    print('🔑 OpenAI API Key present: ${(dotenv.env['OPENAI_API_KEY']?.isNotEmpty ?? false) && dotenv.env['OPENAI_API_KEY'] != 'your_openai_api_key_here'}');
  } catch (e) {
    print('⚠️ .env file not found: $e. AI features will require API key setup.');
  }
  
  runApp(const InvestmentTrackerApp());
}

class InvestmentTrackerApp extends StatelessWidget {
  const InvestmentTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Tracker',
      debugShowCheckedModeBanner: false,
      theme: CredTheme.theme,
      home: const HomeScreen(),
    );
  }
}
