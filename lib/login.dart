import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Handles the user authentication interface.
// Receives [onLoginSuccess] callback to notify the root widget to change the navigation state upon successful login.
class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Global key to manage and validate the state of the form fields.
  final _formKey = GlobalKey<FormState>();
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Reference to the 'akun' (accounts) node in the Firebase Realtime Database.
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('akun');

  bool _isLoading = false;
  String _errorMessage = '';

  // Validates input and authenticates the user against the records in Firebase.
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Fetch all account data from the database.
        final snapshot = await _ref.get();
        
        if (snapshot.exists) {
          final data = snapshot.value as Map;
          final users = data.values.cast<Map>();

          // Iterate through the fetched data to find a matching username and password combination.
          final user = users.firstWhere(
            (user) =>
                user['username'] == _usernameController.text &&
                user['password'] == _passwordController.text,
            // Return an empty map if no match is found to prevent StateError.
            orElse: () => {},
          );

          if (user.isNotEmpty) {
            // Trigger the callback to navigate the user to the HomePage.
            if (widget.onLoginSuccess != null) {
              widget.onLoginSuccess!();
            }
          } else {
            setState(() {
              _errorMessage = 'Username atau password salah';
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Data pengguna tidak ditemukan';
          });
        }
      } catch (e) {
        // Catch and display any network or database connection errors.
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
        });
      } finally {
        // Ensure the loading state is turned off regardless of success or failure.
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose of the text controllers to free up system resources and prevent memory leaks.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Auto Light IoT',
                      style: GoogleFonts.poppins(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Kelompok 19 - Cahaya',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          if (_errorMessage.isNotEmpty) ...[                            
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}