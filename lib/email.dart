import 'package:flutter/material.dart';
import 'acc.dart';
import 'login.dart';

class Email extends StatefulWidget {
  const Email({super.key});

  @override
  State<Email> createState() => _EmailState();
}

class _EmailState extends State<Email> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
          mainAxisAlignment: MainAxisAlignment.start,
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
                        Row(children: [Text('Buat Akun')]),
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
                              return 'Email Tidak Boleh Kosong';
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
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
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
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak sama';
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
                                MaterialPageRoute(builder: (context) => Acc()),
                              );
                            }
                          },
                          child: Text('Buat Akun'),
                        ),
                        SizedBox(width: 30),
                        TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: Size(120, 45),
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
                    'Sudah Punya Akun?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Login()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: Size(280, 45),
                    ),
                    child: Text(
                      'Masuk',
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
