import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'game_beginner.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'finished_game_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordmania',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2E8D9),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E8CAB)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'Wordmania'),
        '/game': (context) => const GameBeginnerPage(),
        '/home': (context) => const HomePage(),
        '/finished': (context) => const FinishedGamePage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> tumRoomlariSil() async {
    try {
      final rooms = await FirebaseFirestore.instance.collection('rooms').get();
      for (var doc in rooms.docs) {
        await doc.reference.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm rooms başarıyla silindi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 40.0),
              child: CircleAvatar(
                radius: 135,
                backgroundImage: AssetImage('assets/wordmania_logo.png'),
                backgroundColor: Colors.transparent,
              ),
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                child: const Text('Giriş Yap'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text('Kayıt Ol'),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 250,
              child: OutlinedButton(
                onPressed: () async {
                  await tumRoomlariSil();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Tüm Rooms\'u Sil (Admin)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
