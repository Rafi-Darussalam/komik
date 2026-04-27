import 'package:flutter/material.dart';
import 'acc.dart';
import 'home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/accbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: EdgeInsets.only(top: 45),
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Column(
              children: [
                Text(
                  'Selamat Datang',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Lumic - Cerita Hebat Dimulai Di Sini',
                  style: TextStyle(fontSize: 12, color: Colors.black38),
                ),
              ],
            ),
            Container(
              height: 250,
              margin: EdgeInsets.only(top: 40, left: 55, right: 55, bottom: 10),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Row(children: [Text('Masuk Ke Akun')]),
                        SizedBox(height: 5),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(50, 45),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => HomePage()),
                              );
                            }
                          },
                          child: Text('Masuk'),
                        ),
                        SizedBox(width: 60),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(100, 45),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => Acc()),
                            );
                          },
                          child: Text('Batal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 55),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.black38),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'atau',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.black38),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Belum Punya Akun?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Acc()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(280, 45),
                    ),
                    child: Text(
                      'Daftar',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
