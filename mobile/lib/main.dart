import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'services/websocket_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations prioritizing landscape mode for Stream Deck / Keypad layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  final storageService = await StorageService.init();
  final wsService = WebSocketService();

  runApp(DevPadApp(
    storageService: storageService,
    wsService: wsService,
  ));
}

class DevPadApp extends StatelessWidget {
  final StorageService storageService;
  final WebSocketService wsService;

  const DevPadApp({
    super.key,
    required this.storageService,
    required this.wsService,
  });

  @override
  Widget build(BuildContext context) {
    // Stream Deck Theme: #0B1017 background, #19212D surfaces, #36E1BD accent
    const backgroundColor = Color(0xFF0B1017);
    const surfaceColor = Color(0xFF19212D);
    const accentColor = Color(0xFF36E1BD);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
      primary: accentColor,
      surface: surfaceColor,
    );

    return MaterialApp(
      title: 'DevPad Stream Deck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
      ),
      home: HomeScreen(
        storageService: storageService,
        wsService: wsService,
      ),
    );
  }
}
