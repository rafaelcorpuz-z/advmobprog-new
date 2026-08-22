import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;

  Future<void> _addToCart(BuildContext context) async {
    try {
      await context.read<CartProvider>().addProduct(product);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to cart')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.15,
              child: Image.network(product.thumbnail, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          CustomText(
            product.category.toUpperCase(),
            fontSize: 12,
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 6),
          CustomText(product.title, fontSize: 26, fontWeight: FontWeight.bold),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 4),
              CustomText(
                '${product.rating.toStringAsFixed(1)} rating  |  ${product.stock} in stock',
              ),
            ],
          ),
          const SizedBox(height: 18),
          CustomText(
            '\$${product.price.toStringAsFixed(2)}',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 18),
          CustomText(product.description, fontSize: 16),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: context.watch<CartProvider>().isAdding
                ? null
                : () => _addToCart(context),
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
