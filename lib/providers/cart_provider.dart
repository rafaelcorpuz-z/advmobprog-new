import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _service = CartService();
  final List<CartProduct> _products = [];
  bool _isAdding = false;

  UnmodifiableListView<CartProduct> get products =>
      UnmodifiableListView(_products);
  bool get isAdding => _isAdding;
  int get totalQuantity =>
      _products.fold(0, (total, product) => total + product.quantity);
  double get total =>
      _products.fold(0, (total, product) => total + product.total);

  Future<void> addProduct(Product product) async {
    if (_isAdding) return;
    _isAdding = true;
    notifyListeners();

    try {
      await _service.addProduct(product: product);
      final existingIndex = _products.indexWhere(
        (item) => item.id == product.id,
      );
      if (existingIndex == -1) {
        _products.add(_cartProductFrom(product));
      } else {
        final existing = _products[existingIndex];
        final quantity = existing.quantity + 1;
        _products[existingIndex] = _cartProductFrom(
          product,
          quantity: quantity,
        );
      }
      notifyListeners();
    } finally {
      _isAdding = false;
      notifyListeners();
    }
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
      _products.removeAt(index);
      notifyListeners();
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
      total: product.price * quantity,
      discountPercentage: product.discountPercentage,
      discountedPrice: product.discountedPrice,
      thumbnail: product.thumbnail,
    );
    notifyListeners();
  }

  CartProduct _cartProductFrom(Product product, {int quantity = 1}) {
    return CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: quantity,
      total: product.price * quantity,
      discountPercentage: 0,
      discountedPrice: product.price,
      thumbnail: product.thumbnail,
    );
  }
}
