import 'package:flutter/material.dart';
import 'email.dart';
import 'login.dart';

class Acc extends StatelessWidget {
  const Acc({super.key});

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
              height: 260,
              margin: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Email()),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFF9112BC),
                      minimumSize: Size(280, 45),
                    ),
                    child: Text(
                      'Daftar Menggunakan Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                        
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFFFFFFF),
                      minimumSize: Size(280, 45),
                    ),
                    child: Text(
                      'Daftar Menggunakan Google',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 55),
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
                        Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => Login())
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
