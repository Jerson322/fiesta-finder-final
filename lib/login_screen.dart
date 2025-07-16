import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool rememberMe = false;
  bool passwordVisible = false; // Controla la visibilidad de la contraseña

  // Método para iniciar sesión con correo y contraseña
  Future<void> _signInWithEmail() async {
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, ingrese su correo y contraseña')),
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verificar si el usuario existe en Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showEmailAccountAlert(); // Aquí llamamos al método
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userCredential.user!),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showEmailAccountAlert(); // Mostrar alerta si el usuario no existe
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión: $e')),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return; // El usuario canceló el inicio de sesión
      }

      // Obtener la autenticación de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con las credenciales de Google
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Verificar si el usuario ya existe en Firestore usando el UID de Firebase Auth
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid) // Usamos el UID de Firebase Auth
          .get();

      if (!userDoc.exists) {
        // Si no existe, mostrar la alerta y redirigir al registro
        _showGoogleAccountAlert();
      } else {
        // Si el usuario ya existe en Firestore, redirigir a la pantalla de inicio
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userCredential.user!),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
      );
    }
  }

  // Alerta si el usuario no existe en la base de datos (para Google)
  void _showGoogleAccountAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('¡Cuenta no encontrada!'),
          content: Text('No hay una cuenta creada con esta cuenta de Google. Por favor, regístrate.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()), // Redirige a la pantalla de registro
                );
              },
              child: Text('Registrarse'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Solo cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Alerta si el usuario no existe en la base de datos (para email)
  void _showEmailAccountAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('¡Cuenta no encontrada!'),
          content: Text('No hay una cuenta creada con este correo electrónico. Por favor, regístrate.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterScreen()), // Redirige a la pantalla de registro
                );
              },
              child: Text('Registrarse'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Solo cierra el diálogo
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/ff.png', height: 100),
                      const SizedBox(height: 20),
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Ingrese su correo electrónico',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: !passwordVisible, // Aquí controlamos la visibilidad de la contraseña
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                passwordVisible = !passwordVisible; // Cambiamos la visibilidad de la contraseña
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recordarme'),
                          Switch(
                            value: rememberMe,
                            onChanged: (bool value) {
                              setState(() {
                                rememberMe = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signInWithEmail, // Llama al nuevo método para login con correo
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 39, 48, 176),
                          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text('INGRESAR', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 20),
                      const Text('También puedes iniciar sesión con ...'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.facebook, size: 40, color: Colors.blue),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.apple, size: 40, color: Colors.black),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.g_mobiledata, size: 40, color: Colors.red),
                            onPressed: _signInWithGoogle, // Llama al método para login con Google
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegisterScreen()),
                          );
                        },
                        child: const Text(
                          '¿No tienes cuenta? lloralo Regístrate',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.1), // Espacio adicional para asegurar centrado
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}