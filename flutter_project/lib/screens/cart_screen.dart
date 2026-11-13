import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../service/cart_service.dart';
import '../utils/formatters.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  void _confirmRemove(String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover item'),
        content: Text('Deseja remover "$productName" do carrinho?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _cartService.removeItem(productId);
              Navigator.pop(ctx);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _calculateShipping() {
    try {
      _cartService.calculateShipping(_cepController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frete calculado com sucesso!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _applyCoupon() {
    try {
      _cartService.applyCoupon(_couponController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cupom aplicado!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _checkout() async {
    if (_cartService.items.isEmpty) return;
    
    // Mostra o loading para o usuário não clicar duas vezes
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      // Chama o MockAPI e limpa o Firestore
      await _cartService.finalizarPedido();
      
      if (mounted) Navigator.pop(context); // Fecha o loading circular
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pedido Finalizado', style: TextStyle(color: Color(0xFF6B8E99))),
            content: const Text('Seu pedido foi processado e enviado com sucesso!'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
                onPressed: () {
                  Navigator.pop(ctx); // Fecha o modal
                  Navigator.pop(context); // Volta para a tela de produtos
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Fecha o loading circular
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6B8E99),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _cartService,
        builder: (context, _) {
          if (_cartService.items.isEmpty) {
            return const Center(
              child: Text('Seu carrinho está vazio.', style: TextStyle(fontSize: 18)),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cartService.items.length,
                  itemBuilder: (context, index) {
                    final item = _cartService.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            (item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.product.imageUrl!,
                                      width: 60, height: 60, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                                    ),
                                  )
                                : _buildPlaceholder(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(_currencyFormat.format(item.product.price), style: TextStyle(color: Colors.pink.shade300, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _cartService.updateQuantity(item.product.id!, item.quantity - 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _cartService.updateQuantity(item.product.id!, item.quantity + 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmRemove(item.product.id!, item.product.name),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildBottomSummary(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -5), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cepController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CepInputFormatter()],
                  decoration: const InputDecoration(labelText: 'CEP', isDense: true, border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E99)),
                onPressed: _calculateShipping,
                child: const Text('Calcular', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: const InputDecoration(labelText: 'Cupom de Desconto', isDense: true, border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E99)),
                onPressed: _applyCoupon,
                child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal:'), Text(_currencyFormat.format(_cartService.subtotal))]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Frete:'), Text(_currencyFormat.format(_cartService.shippingCost))]),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Desconto:'), Text('- ${_currencyFormat.format(_cartService.discount)}', style: const TextStyle(color: Colors.green))]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_currencyFormat.format(_cartService.total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink.shade300)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade300),
              onPressed: _checkout,
              child: const Text('FINALIZAR PEDIDO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}