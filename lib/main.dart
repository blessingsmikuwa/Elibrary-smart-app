 import 'package:flutter/material.dart';

void main() {
  runApp(const ELibraryApp());
}

class ELibraryApp extends StatelessWidget {
  const ELibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eLibrary Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'eLibrary Mobile App',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}