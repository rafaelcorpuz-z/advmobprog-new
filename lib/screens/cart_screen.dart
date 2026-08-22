import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';
import 'product_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final products = cartProvider.products;
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                    tooltip: 'Home',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.home_outlined),
                    onPressed: () =>
                        Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Cart',
                    color: Theme.of(context).colorScheme.primary,
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {},
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Profile',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.person_outline),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: products.isEmpty
          ? const Center(child: CustomText('Your cart is empty'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: products.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return _CartSummary(
                    totalQuantity: cartProvider.totalQuantity,
                    total: cartProvider.total,
                  );
                }
                return _CartItem(product: products[index]);
              },
            ),
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({required this.product});
  final CartProduct product;

  @override
  Widget build(BuildContext context) {
    final detailProduct = Product.fromJson(product.toJson());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductScreen(product: detailProduct),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) =>
                      const Icon(Icons.image_not_supported_outlined),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      product.title,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty ${product.quantity}  |  \$${product.discountedPrice.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuantityButton(
                    icon: Icons.add,
                    tooltip: 'Increase quantity',
                    onPressed: () => context
                        .read<CartProvider>()
                        .increaseQuantity(product.id),
                  ),
                  SizedBox(
                    height: 18,
                    child: Center(
                      child: Text(
                        '${product.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _QuantityButton(
                    icon: Icons.remove,
                    tooltip: 'Decrease quantity',
                    onPressed: () => context
                        .read<CartProvider>()
                        .decreaseQuantity(product.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.totalQuantity, required this.total});
  final int totalQuantity;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText('$totalQuantity items', color: Colors.grey),
          const SizedBox(height: 6),
          CustomText(
            'Total  \$${total.toStringAsFixed(2)}',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
