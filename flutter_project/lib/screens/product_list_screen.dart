import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product.dart';
import '../service/product_service.dart';
import '../service/cart_service.dart'; // Import do serviço do carrinho
import 'product_form_screen.dart';
import 'cart_screen.dart'; // Import da tela do carrinho

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  String _searchQuery = '';
  
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadDataSilently();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _productService.listarTodos();
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDataSilently() async {
    try {
      final data = await _productService.listarTodos();
      if (mounted) {
        setState(() {
          _products = data;
        });
      }
    } catch (e) {
      // Ignora erro silencioso
    }
  }

  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: const Text('Tem certeza que deseja excluir este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _productService.excluir(productId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produto excluído com sucesso!')),
                  );
                  _loadInitialData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _confirmAddToCart(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar ao Carrinho', style: TextStyle(color: Color(0xFF6B8E99))),
        content: Text('Deseja adicionar "${product.name}" ao seu carrinho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx); // Fecha o modal
              CartService().addItem(product); // Adiciona ao carrinho
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} adicionado ao carrinho!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6B8E99),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // BOTÃO NOVO: Abre a tela do carrinho
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Pesquisar produto...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B8E99)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              color: const Color(0xFF6B8E99),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink.shade300,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          );
          if (result == true) _loadInitialData();
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
        child: Text('Erro ao carregar dados:\n$_errorMessage', textAlign: TextAlign.center),
      );
    }
    
    if (_products.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 300),
          Center(child: Text('Nenhum produto cadastrado.')),
        ],
      );
    }

    final filteredProducts = _products
        .where((p) => p.name.toLowerCase().contains(_searchQuery))
        .toList();

    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50, height: 50, color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )
                : Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
            title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estoque: ${product.quantity} unidade(s)   Adicionado em ${product.date}'),
                Text(
                  product.isAvailable ? 'Disponível' : 'Esgotado',
                  style: TextStyle(
                    color: product.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            // AÇÃO DO CLIQUE NO PRODUTO: Mostra os detalhes (exigência da avaliação)
            onTap: () async {
              try {
                final detalhes = await _productService.consultarPorId(product.id!);
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(detalhes.name),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descrição: ${detalhes.description}'),
                          Text('Preço: R\$ ${detalhes.price.toStringAsFixed(2)}'),
                          Text('Quantidade: ${detalhes.quantity}'),
                          Text('Data: ${detalhes.date} às ${detalhes.time}'),
                          Text('Obs: ${detalhes.observation}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Fechar'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar detalhes: $e')));
                }
              }
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. BOTÃO DE ADICIONAR AO CARRINHO (NOVO)
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                  onPressed: () => _confirmAddToCart(product),
                ),
                // 2. BOTÃO DE EDITAR PRODUTO
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF6B8E99)),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
                    );
                    if (result == true) _loadInitialData();
                  },
                ),
                // 3. BOTÃO DE DELETAR PRODUTO
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(product.id!),
                  
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }
}