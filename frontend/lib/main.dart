import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'start.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _homeWidget = const Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      if (token != null && token.isNotEmpty) {
        _homeWidget = const HomePage();
      } else {
        _homeWidget = const StartPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'lumic',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: _homeWidget,
    );
  }
}