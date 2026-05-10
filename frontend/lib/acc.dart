import 'dart:ui';
import 'package:flutter/material.dart';
import 'email.dart';
import 'login.dart';

class Acc extends StatelessWidget {
  const Acc({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/accbg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo.png', width: 100, height: 100, fit: BoxFit.contain),
                  const SizedBox(height: 20),
                  const Text(
                    'LUMIC',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF333333),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Explore Millions of Stories',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 70),

                  // Choice Buttons - Simpler Style
                  _buildChoiceButton(
                    context: context,
                    text: 'DAFTAR SEKARANG',
                    isPrimary: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Email()),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildChoiceButton(
                    context: context,
                    text: 'MASUK',
                    isPrimary: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Dengan melanjutkan, Anda setuju dengan Syarat & Ketentuan kami.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton({
    required BuildContext context,
    required String text,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF9C27B0) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF333333),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary ? BorderSide.none : const BorderSide(color: Colors.black12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
