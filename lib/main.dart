import 'package:drawer/features/draw/draw_screen.dart';
import 'package:drawer/features/draw/models/offset.dart';
import 'package:drawer/features/draw/models/stroke.dart';
import 'package:drawer/features/home/home_screen.dart';
import 'package:drawer/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // register adapters
  Hive.registerAdapter(OffsetCustomAdapter());
  Hive.registerAdapter(StrokeAdapter());
  await Hive.openBox<Map<dynamic, dynamic>>('drawings');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keane Kean',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/draw': (context) => DrawScreen(),
      },
    );
  }
}
