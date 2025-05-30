import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _Login1State();
}

class _Login1State extends State<Login> {
  @override
  void initState() {
    super.initState();

    // TARUH LISTENER DI SINI
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      print("SESSION: ${session?.accessToken}");

      if (session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Image.asset(
              "assets/nike.jpg",
              fit: BoxFit.cover,
              height: double.infinity,
            ),
            Positioned(
              top: 60,
              right: 10,
              child: Text(
                "WELCOME",
                style: TextStyle(color: Colors.red, fontSize: 30),
              ),
            ),
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Card(
                color: Colors.white10,
                elevation: 16.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Silahkan Login",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 50,
                        right: 50,
                        bottom: 20,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(9.0),
                          child: InkWell(
                            onTap: () async {
                              try {
                                await Supabase.instance.client.auth
                                    .signInWithOAuth(
                                      OAuthProvider.google,
                                      redirectTo:
                                          'com.example.inventory://callback',
                                    );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login gagal: $e')),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("assets/logo.jpg", width: 40),
                                SizedBox(width: 5),
                                Text(
                                  "Login with Google",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
