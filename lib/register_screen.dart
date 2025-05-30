import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiesta_finder/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController documentNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nitController = TextEditingController();

  String documentType = 'Cédula';
  String personType = 'Usuario';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    return RegExp(r"^(?=.*[A-Z])(?=.*\d).{6,}$").hasMatch(password);
  }

  bool _isNumeric(String str) {
    return RegExp(r'^[0-9]+$').hasMatch(str);
  }

  Future<void> _register() async {
    if (!_isEmailValid(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo inválido')),
      );
      return;
    }
    if (!_isPasswordValid(passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña inválida: Debe tener al menos 6 caracteres, una mayúscula y un número.',
          ),
        ),
      );
      return;
    }
    if (!_isNumeric(documentNumberController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El número de documento debe contener solo números.')),
      );
      return;
    }
    if (personType == 'Empresario' && !_isNumeric(nitController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El NIT debe contener solo números.')),
      );
      return;
    }
    if (personType == 'Administrador' && !emailController.text.endsWith('@admin.com')) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Los administradores deben registrarse con un correo @admin.com')),
  );
  return;
}

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
  'nombre': nameController.text.trim(),
  'correo': emailController.text.trim(),
  'tipoDocumento': documentType,
  'numeroDocumento': documentNumberController.text.trim(),
  'tipoPersona': personType,
  if (personType == 'Empresario') 'NIT': nitController.text.trim(),
  'isAdmin': personType == 'Administrador', // Agregar este campo
});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userCredential.user!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrarse: $e')));
    }
  }

  Future<void> _registerWithGoogle() async {
    await GoogleSignIn().signOut();
    bool shouldRegisterAsUser = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('¿Registrarse como Usuario?'),
          content: Text('Si te registras con Google, serás registrado como Usuario. Si deseas registrarte como Empresario, debes llenar los datos adicionales.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldRegisterAsUser = true;
              },
              child: Text('Registrar como Usuario'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldRegisterAsUser = false;
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (shouldRegisterAsUser) {
      try {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);

        await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
          'nombre': userCredential.user?.displayName ?? '',
          'correo': userCredential.user?.email ?? '',
          'tipoPersona': 'Usuario',
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userCredential.user!),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrarse con Google: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                color: const Color(0xFFFDF3F9),
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/ff.png', height: 90),
                      const SizedBox(height: 15),
                      const Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(nameController, 'Nombre', Icons.person),
                      const SizedBox(height: 12),
                      _buildTextField(emailController, 'Correo', Icons.email,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _buildDropdown(
                        'Tipo de documento',
                        documentType,
                        ['Cédula', 'Cédula extranjera'],
                        (value) {
                          setState(() {
                            documentType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        documentNumberController,
                        'Número de documento',
                        Icons.badge,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        passwordController,
                        'Contraseña',
                        Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdown(
  'Tipo de persona',
  personType,
  ['Usuario', 'Empresario', 'Administrador'], // Agregar 'Administrador'
  (value) {
    setState(() {
      personType = value!;
      if (value != 'Empresario') {
        nitController.clear();
      }
    });
  },
),
                      const SizedBox(height: 12),
                      if (personType == 'Empresario')
                        _buildTextField(
                          nitController,
                          'NIT de la empresa',
                          Icons.business,
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 20),
                      _buildElevatedButton(
                        'Registrarse',
                        _register,
                        const Color.fromARGB(255, 39, 48, 176),
                      ),
                      const SizedBox(height: 10),
                      _buildGoogleButton(),
                      const SizedBox(height: 15),
                      _buildLoginText(),
                      SizedBox(height: constraints.maxHeight * 0.1),
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

  Widget _buildGoogleButton() {
    return SizedBox(
      width: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _registerWithGoogle,
            icon: Image.asset('assets/google.png', width: 40, height: 40),
            tooltip: 'Registrarse con Google',
          ),
        ],
      ),
    );
  }

  Widget _buildLoginText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿Ya tienes cuenta? '),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            );
          },
          child: const Text(
            'Inicia sesión',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 39, 48, 176)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: const TextStyle(fontSize: 16)),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.list, color: const Color.fromARGB(255, 39, 48, 176)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
      menuMaxHeight: 300,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
    );
  }

  Widget _buildElevatedButton(
    String label,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}

