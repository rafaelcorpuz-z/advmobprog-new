import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';

import '../widgets/custom_text.dart';

// Enhancement 1: renders the cart from the new API endpoint (getUserCart).

// Enhancement 2: no chat FAB on this screen — it's only added in HomeScreen's

// Stack, so it's naturally hidden here.

class CartScreen extends StatefulWidget {

  const CartScreen({super.key});

  @override

  State<CartScreen> createState() => _CartScreenState();

}

class _CartScreenState extends State<CartScreen> {

  @override

  void initState() {

    super.initState();

  }

  @override

  Widget build(BuildContext context) {

    final cart = context.watch<CartProvider>();

    return Scaffold(

      appBar: AppBar(

        title: const CustomText('Cart', fontSize: 22, fontWeight: FontWeight.bold),

      ),

      body: cart.isLoading

          ? const Center(child: CircularProgressIndicator())

          : cart.products.isEmpty

              ? const Center(child: CustomText('Your cart is empty'))

              : ListView.builder(

                  padding: const EdgeInsets.all(16),

                  itemCount: cart.products.length,

                  itemBuilder: (context, index) {

                    final item = cart.products[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.thumbnail,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, stackTrace) => const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    item.title,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 4),
                                  CustomText(
                                    '${item.discountPercentage.toStringAsFixed(0)}% off • \$${item.total.toStringAsFixed(2)} total',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add),
                                  onPressed: () => context
                                      .read<CartProvider>()
                                      .increaseQuantity(item.id),
                                ),
                                Text('${item.quantity}'),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => context
                                      .read<CartProvider>()
                                      .decreaseQuantity(item.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                  },

                ),

      bottomNavigationBar: cart.products.isEmpty

          ? null

          : Padding(

              padding: const EdgeInsets.all(16),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText('Subtotal:', fontWeight: FontWeight.bold),
                      CustomText('\$${cart.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CustomText('Discounted total:', fontWeight: FontWeight.bold),
                      CustomText('\$${cart.discountedTotal.toStringAsFixed(2)}'),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(

                    width: double.infinity,

                    child: FilledButton(

                      onPressed: () {

                        ScaffoldMessenger.of(context).showSnackBar(

                          const SnackBar(content: Text('Order confirmed')),

                        );

                      },

                      child: const Text('Confirm Order'),

                    ),

                  ),

                ],

              ),

            ),

    );

  }

}
 