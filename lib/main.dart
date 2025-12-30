import 'package:flutter/material.dart';
import 'package:laundry/screens/homescreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laundry Report',
      debugShowCheckedModeBanner: false,
      home: Homescreen(),
    );
  }
}
