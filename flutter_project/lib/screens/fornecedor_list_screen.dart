import 'dart:async';
import 'package:flutter/material.dart';
import '../models/fornecedor.dart';
import '../service/fornecedor_service.dart';
import 'fornecedor_form_screen.dart';

class FornecedorListScreen extends StatefulWidget {
  const FornecedorListScreen({super.key});

  @override
  State<FornecedorListScreen> createState() => _FornecedorListScreenState();
}

class _FornecedorListScreenState extends State<FornecedorListScreen> {
  final FornecedorService _service = FornecedorService();
  List<FornecedorModel> _fornecedores = [];
  bool _isLoading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _carregarSilencioso());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dados = await _service.listarTodos();
      if (mounted) setState(() { _fornecedores = dados; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _carregarSilencioso() async {
    try {
      final dados = await _service.listarTodos();
      if (mounted) setState(() => _fornecedores = dados);
    } catch (_) {}
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: const Text('Tem certeza que deseja excluir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.excluir(id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído com sucesso!')));
                  _carregarDados();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fornecedores', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF6B8E99), iconTheme: const IconThemeData(color: Colors.white)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('$_error', textAlign: TextAlign.center))
              : _fornecedores.isEmpty
                  ? const Center(child: Text('Nenhum fornecedor encontrado.'))
                  : ListView.builder(
                      itemCount: _fornecedores.length,
                      itemBuilder: (context, index) {
                        final f = _fornecedores[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(f.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.business)),
                            ),
                            title: Text(f.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('CNPJ: ${f.cnpj}\nE-mail: ${f.email}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Color(0xFF6B8E99)),
                                  onPressed: () async {
                                    final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => FornecedorFormScreen(fornecedor: f)));
                                    if (res == true) _carregarDados();
                                  },
                                ),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmarExclusao(f.id!)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink.shade300,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => const FornecedorFormScreen()));
          if (res == true) _carregarDados();
        },
      ),
    );
  }
}