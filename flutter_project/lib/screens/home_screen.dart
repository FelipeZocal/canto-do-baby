import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canto do Baby'),
        backgroundColor: const Color(0xFF6B8E99),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8F4F8), Color(0xFFFFF0F5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/Canto do Baby.png', width: 200, height: 200),
              const SizedBox(height: 20),
              const Text(
                'Bem-vindo ao Canto do Baby!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6B8E99)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}