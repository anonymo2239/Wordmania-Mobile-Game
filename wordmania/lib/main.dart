import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordmania',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2E8D9), // Arka plan
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2E8CAB)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Wordmania'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: const CircleAvatar(
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
          ],
        ),
      ),
    );
  }
}
