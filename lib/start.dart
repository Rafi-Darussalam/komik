import 'package:flutter/material.dart';
import 'acc.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover
          )
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lumic', 
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white
                    ),
                  textAlign: TextAlign.left),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  padding: EdgeInsets.all(0),
                  width: 270,
                  child: Column(
                    children: [
                      Text(
                        'Cerita Hebat Dimulai Di Sini',
                        style: TextStyle(
                          fontSize: 44,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Acc(),
                      )
                    );
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size(250, 60),
                    backgroundColor: Color(0xFF9112BC)
                  ),
                  child: Text(
                    'Mulai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
