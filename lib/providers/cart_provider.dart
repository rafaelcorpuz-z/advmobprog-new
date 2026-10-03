import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _service = CartService();
  final List<CartProduct> _products = [];
  bool _isAdding = false;
  bool _isLoading = false;

  UnmodifiableListView<CartProduct> get products =>
      UnmodifiableListView(_products);
  bool get isAdding => _isAdding;
  bool get isLoading => _isLoading;

  int get totalQuantity =>
      _products.fold(0, (total, product) => total + product.quantity);

  double get subtotal => _products.fold(
      0,
      (sum, product) => sum + (product.price * product.quantity),
    );

  double get discountedTotal => _products.fold(
      0,
      (sum, product) => sum + product.total,
    );

  double get total => discountedTotal;

  Future<void> fetchUserCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cart = await _service.getCartByUserId();
      _products
        ..clear()
        ..addAll(cart?.products ?? const <CartProduct>[]);
    } catch (_) {
      _products.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    if (_isAdding) return;

    _isAdding = true;
    notifyListeners();

    try {
      final index = _products.indexWhere((item) => item.id == product.id);

      if (index >= 0) {
        final existing = _products[index];
        final newQuantity = existing.quantity + 1;
        _products[index] = CartProduct(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: newQuantity,
          total: existing.discountedPrice * newQuantity,
          discountPercentage: existing.discountPercentage,
          discountedPrice: existing.discountedPrice,
          thumbnail: existing.thumbnail,
        );
      } else {
        _products.add(
          CartProduct(
            id: product.id,
            title: product.title,
            price: product.price,
            quantity: 1,
            total: product.discountedPrice,
            discountPercentage: product.discountPercentage,
            discountedPrice: product.discountedPrice,
            thumbnail: product.thumbnail,
          ),
        );
      }

      await _service.addProduct(product: product);
      notifyListeners();
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  void removeProduct(int productId) {
    final index = _products.indexWhere((item) => item.id == productId);
    if (index == -1) return;
    _products.removeAt(index);
    notifyListeners();
  }

  void increaseQuantity(int productId) {
    final index = _products.indexWhere((item) => item.id == productId);
    if (index == -1) return;
    _setQuantity(index, _products[index].quantity + 1);
  }

  void decreaseQuantity(int productId) {
    final index = _products.indexWhere((item) => item.id == productId);
    if (index == -1) return;
    if (_products[index].quantity <= 1) {
      removeProduct(productId);
      return;
    }
    _setQuantity(index, _products[index].quantity - 1);
  }

  void _setQuantity(int index, int quantity) {
    final product = _products[index];
    _products[index] = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: product.discountedPrice * quantity,
      discountPercentage: product.discountPercentage,
      discountedPrice: product.discountedPrice,
      thumbnail: product.thumbnail,
    );
    notifyListeners();
  }
}
