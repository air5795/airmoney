import 'dart:io';
import 'package:app_gastos/http_overrides.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/estado_app.dart';
import 'screens/pantalla_splash.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase no se pudo inicializar. Se activara el modo Demo de forma automatica.');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => EstadoApp(),
      child: const GastosApp(),
    ),
  );
}

class GastosApp extends StatelessWidget {
  const GastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final estadoApp = Provider.of<EstadoApp>(context);
    final esOscuro = estadoApp.esTemaOscuro;
    final colorMarca = estadoApp.colorPrincipal;

    return MaterialApp(
      title: 'AirMoney',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: esOscuro ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: esOscuro ? const Color(0xFF000000) : const Color(0xFFF8FAFC),
        primaryColor: colorMarca,
        colorScheme: esOscuro
            ? ColorScheme.dark(
                primary: colorMarca,
                secondary: const Color(0xFF10B981), // Emerald 500 (Ingresos)
                surface: const Color(0xFF0A0A0A),   // Neutral Pitch Black (Tarjetas oscuras)
                error: const Color(0xFFEF4444),     // Red 500 (Gastos)
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: const Color(0xFFF1F5F9),
              )
            : ColorScheme.light(
                primary: colorMarca,
                secondary: const Color(0xFF059669), // Emerald 600 (Ingresos)
                surface: Colors.white,               // Blanco puro (Tarjetas claras)
                error: const Color(0xFFDC2626),     // Red 600 (Gastos)
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: const Color(0xFF0F172A),
              ),
        fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
        textTheme: GoogleFonts.ibmPlexSansTextTheme(
          ThemeData(brightness: esOscuro ? Brightness.dark : Brightness.light).textTheme,
        ).copyWith(
          displayLarge: TextStyle(
            color: esOscuro ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
          titleLarge: TextStyle(
            color: esOscuro ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            color: esOscuro ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: esOscuro ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            fontSize: 14,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            color: esOscuro ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: esOscuro ? const Color(0xFF0E0E0E) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: esOscuro
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: esOscuro ? const Color(0xFF0A0A0A) : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const PantallaSplash(),
    );
  }
}
