// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'services/db_helper.dart';
import 'services/notification_service.dart';
import 'services/budget_service.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Bildirim servisini başlat
  await NotificationService.init();

  // Sadece Android 13+ için izin iste
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print('🚫 Bildirim izni verilmedi!');
    }
  }

  // Test bildirimi planla (5 sn sonra)
  await NotificationService.scheduleNotification(
    id: 0,
    title: 'Test Başlık',
    body: 'Test mesajı geliyor',
    scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
  );

  // Veritabanını önceden açmak (opsiyonel)
  await DBHelper.instance.database;

  // ► ThemeProvider'ı en dışa ekleyip sarıyoruz
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobil Finans Yönetimi',
      theme: ThemeData(
        // Seed edilen renk paleti ve Material 3
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProv.primarySwatch,
          brightness: Brightness.light,
        ),
        useMaterial3: true,

        // AppBar
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          iconTheme: IconThemeData(color: Colors.black54),
        ),

        // BottomNavigationBar
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          showUnselectedLabels: true,
          selectedIconTheme: const IconThemeData(size: 28),
          unselectedIconTheme: const IconThemeData(size: 24),
          selectedItemColor: themeProv.primarySwatch,
          unselectedItemColor: Colors.grey,
        ),

        // Form alanları
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Card
        cardTheme: CardTheme(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // Genel yazı teması
        textTheme: Typography.material2018(
          black: Typography.blackMountainView,
        ).black.apply(fontFamily: 'Roboto'),
      ),
      darkTheme: ThemeData(
        // Seed edilen renk paleti ve Material 3 (koyu)
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeProv.primarySwatch,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,

        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),

        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 8,
          showUnselectedLabels: true,
          selectedIconTheme: const IconThemeData(size: 28),
          unselectedIconTheme: const IconThemeData(size: 24),
          selectedItemColor: themeProv.primarySwatch.shade200,
          unselectedItemColor: Colors.grey,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        cardTheme: CardTheme(
          color: Colors.grey.shade900,
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        textTheme: Typography.material2018(
          white: Typography.whiteMountainView,
        ).white.apply(fontFamily: 'Roboto'),
      ),
      themeMode: themeProv.themeMode,
      home: const HomePage(),
    );
  }
}
