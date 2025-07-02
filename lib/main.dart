import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart'; // Agrega esta línea
import 'home_screen.dart'; // Agrega esta línea
import 'package:fiesta_finder/login_screen.dart' as login;
import 'package:fiesta_finder/register_screen.dart' as register;
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null); // Inicializa para español
  runApp(const FiestaFinderApp());
}

class FiestaFinderApp extends StatelessWidget {
  const FiestaFinderApp({super.key});

  @override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const SplashScreen(),
    routes: {
      '/welcome': (context) => const WelcomeScreen(),
      '/login': (context) => const login.LoginScreen(),
      '/register': (context) => const register.RegisterScreen(),
      '/home': (context) => HomeScreen(FirebaseAuth.instance.currentUser!), // Esta es la pantalla principal
    },
  );
}
}
