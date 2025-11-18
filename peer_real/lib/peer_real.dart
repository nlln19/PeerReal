import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

class PeerReal extends StatelessWidget {
  const PeerReal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PeerReal",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
          bodyMedium: GoogleFonts.inter(),
          bodySmall: GoogleFonts.inter(),
        ),
      ),

      debugShowCheckedModeBanner:
          false, // Debug-Banner ausblenden (bitte nid lösche😭)
      home: const HomeScreen(),
    );
  }
}
