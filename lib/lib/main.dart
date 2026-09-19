import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: LabelHargaApp()));
}

class LabelHargaApp extends StatelessWidget {
  const LabelHargaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Label Harga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2A9D8F),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
