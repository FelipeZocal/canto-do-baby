import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  // SUBSTITUA ESTA URL PELA SUA URL DO MOCKAPI.IO OU PLATAFORMA ESCOLHIDA
  final String baseUrl = 'https://6ad60d62f71f154ac486615f.mockapi.io/api/v1/products';

  // CREATE - Cadastrar
  Future<void> cadastrar(ProductModel product) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toMap()),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Erro durante o cadastro. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API ou API indisponível: $e');
    }
  }

  // READ - Consultar todos
  Future<List<ProductModel>> listarTodos() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) {
          // O MockAPI geralmente retorna o ID como 'id' dentro do JSON
          return ProductModel.fromMap(item, item['id']?.toString() ?? '');
        }).toList();
      } else {
        throw Exception('Erro durante a consulta. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API: $e');
    }
  }

  // READ - Consultar por ID
  Future<ProductModel> consultarPorId(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));

      if (response.statusCode == 200) {
        return ProductModel.fromMap(jsonDecode(response.body), id);
      } else {
        throw Exception('Produto não encontrado.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API.');
    }
  }

  // UPDATE - Alterar
  Future<void> atualizar(ProductModel product) async {
    if (product.id == null) throw Exception('ID do produto inválido');
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toMap()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro durante a alteração.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API: $e');
    }
  }

  // DELETE - Excluir
  Future<void> excluir(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erro durante a exclusão.');
      }
    } catch (e) {
      throw Exception('Falha na conexão com a API: $e');
    }
  }
}