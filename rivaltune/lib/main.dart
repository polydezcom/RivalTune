import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_size/window_size.dart' show setWindowFrame, setWindowMinSize, setWindowTitle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'presentation/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    setWindowMinSize(const Size(300, 400));
    
    SharedPreferences.getInstance().then((prefs) {
      final double? savedWidth = prefs.getDouble('window_width');
      final double? savedHeight = prefs.getDouble('window_height');
      
      if (savedWidth != null && savedHeight != null) {
        setWindowFrame(Rect.fromLTWH(0, 0, savedWidth, savedHeight));
      } else {
        setWindowFrame(const Rect.fromLTWH(0, 0, 650, 750));
      }
    });
    
    setWindowTitle('SteelSeries Configurator');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SteelSeries Configurator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme().copyWith(
          titleLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500),
          titleMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.roboto(fontSize: 14),
          bodyMedium: GoogleFonts.roboto(fontSize: 13),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
