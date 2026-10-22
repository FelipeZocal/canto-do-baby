import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fornecedor.dart';

class FornecedorService {
  // Crie um endpoint "fornecedores" no MockAPI.io e cole a URL aqui
  final String baseUrl = 'https://6ad60d62f71f154ac486615f.mockapi.io/api/v1/fornecedores';

  Future<void> cadastrar(FornecedorModel fornecedor) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(fornecedor.toMap()),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Erro durante o cadastro. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API ou API indisponível.');
    }
  }

  Future<List<FornecedorModel>> listarTodos() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => FornecedorModel.fromMap(item, item['id'].toString())).toList();
      } else {
        throw Exception('Erro durante a consulta. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API.');
    }
  }

  Future<FornecedorModel> consultarPorId(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        return FornecedorModel.fromMap(jsonDecode(response.body), id);
      } else {
        throw Exception('Erro durante a consulta: Fornecedor não encontrado.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API.');
    }
  }

  Future<void> atualizar(FornecedorModel fornecedor) async {
    if (fornecedor.id == null) throw Exception('ID inválido');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${fornecedor.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(fornecedor.toMap()),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro durante a alteração.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API.');
    }
  }

  Future<void> excluir(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro durante a exclusão.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API.');
    }
  }
}