import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _service = ProductService();
  final TextEditingController _searchController = TextEditingController();
  late final Future<List<Product>> _productsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productsFuture = _service.getAllProducts();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          'Discover products',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<List<Product>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorView(message: snapshot.error.toString());
                }

                final products = (snapshot.data ?? []).where((product) {
                  return product.title.toLowerCase().contains(_query) ||
                      product.category.toLowerCase().contains(_query);
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      // Enhancement 1: search filters the API article/product list above the cards.
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.clear),
                                  onPressed: _searchController.clear,
                                ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (products.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CustomText('No products found')),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: .72,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) =>
                              _ProductCard(product: products[index]),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned.fill(child: _MovableChatButton()),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                    tooltip: 'Home',
                    color: Theme.of(context).colorScheme.primary,
                    icon: const Icon(Icons.home),
                    onPressed: () {},
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Chats',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => Navigator.pushNamed(context, '/chats'),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    tooltip: 'Profile',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MovableChatButton extends StatefulWidget {
  const _MovableChatButton();

  @override
  State<_MovableChatButton> createState() => _MovableChatButtonState();
}

class _MovableChatButtonState extends State<_MovableChatButton> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final position =
            _position ??
            Offset(constraints.maxWidth - 76, constraints.maxHeight - 76);
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Draggable<int>(
                data: 1,
                feedback: _chatButton(opacity: 0.8),
                childWhenDragging: _chatButton(opacity: 0.35),
                onDragEnd: (details) {
                  final renderBox = context.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.offset);
                  setState(() {
                    _position = Offset(
                      localPosition.dx.clamp(0, constraints.maxWidth - 60),
                      localPosition.dy.clamp(0, constraints.maxHeight - 60),
                    );
                  });
                },
                child: _chatButton(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chatButton({double opacity = 1}) {
    return Opacity(
      opacity: opacity,
      child: FloatingActionButton(
        tooltip: 'Chat support',
        onPressed: () => Navigator.pushNamed(context, '/chats'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Enhancement 2: tapping a card opens the product details page.
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductScreen(product: product)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                product.thumbnail,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => const Center(
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    product.category.toUpperCase(),
                    fontSize: 10,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    product.title,
                    fontWeight: FontWeight.bold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    '\$${product.price.toStringAsFixed(2)}',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CustomText(message, textAlign: TextAlign.center),
      ),
    );
  }
}