import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    if (text.length > 11) return oldValue;

    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Cria a conta de autenticação
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 2. Grava Nome e Telefone no Cloud Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
          );
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Erro ao cadastrar.';
        if (e.code == 'email-already-in-use') {
          message = 'Este e-mail já está em uso.';
        } else if (e.code == 'weak-password') {
          message = 'A senha fornecida é muito fraca.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro de banco de dados: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, PhoneInputFormatter()],
                      decoration: const InputDecoration(labelText: 'Telefone', hintText: '(00) 00000-0000', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o telefone';
                        if (v.replaceAll(RegExp(r'\D'), '').length < 10) return 'Telefone incompleto';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
                      validator: (v) => (v == null || v.length < 6) ? 'A senha deve ter no mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Cadastrar', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}