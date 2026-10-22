import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fornecedor.dart';
import '../service/fornecedor_service.dart';
import '../utils/formatters.dart';

class FornecedorFormScreen extends StatefulWidget {
  final FornecedorModel? fornecedor;
  const FornecedorFormScreen({super.key, this.fornecedor});

  @override
  State<FornecedorFormScreen> createState() => _FornecedorFormScreenState();
}

class _FornecedorFormScreenState extends State<FornecedorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FornecedorService _service = FornecedorService();
  late TextEditingController _nomeCtrl, _cnpjCtrl, _telCtrl, _emailCtrl, _imgCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final f = widget.fornecedor;
    _nomeCtrl = TextEditingController(text: f?.nome ?? '');
    _cnpjCtrl = TextEditingController(text: f?.cnpj ?? '');
    _telCtrl = TextEditingController(text: f?.telefone ?? '');
    _emailCtrl = TextEditingController(text: f?.email ?? '');
    _imgCtrl = TextEditingController(text: f?.imageUrl ?? '');
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final f = FornecedorModel(
          id: widget.fornecedor?.id,
          nome: _nomeCtrl.text.trim(),
          cnpj: _cnpjCtrl.text.trim(),
          telefone: _telCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          imageUrl: _imgCtrl.text.trim(),
        );

        if (widget.fornecedor == null) {
          await _service.cadastrar(f);
        } else {
          await _service.atualizar(f);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.fornecedor == null ? 'Cadastrado com sucesso!' : 'Alterado com sucesso!')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos obrigatórios não preenchidos.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fornecedor == null ? 'Novo Fornecedor' : 'Editar Fornecedor', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6B8E99),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnpjCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, CnpjInputFormatter()],
                decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                validator: (v) => v!.length < 18 ? 'CNPJ inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, PhoneInputFormatter()],
                decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                validator: (v) => !v!.contains('@') ? 'Dados inválidos' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imgCtrl,
                decoration: const InputDecoration(labelText: 'URL da Imagem', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image)),
                validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
                  onPressed: _isLoading ? null : _salvar,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}