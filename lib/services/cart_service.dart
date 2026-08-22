import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';
import '../models/product_model.dart';

class CartService {
  Future<Cart> fetchCart() async {
    final response = await http.get(Uri.parse(cartEndpoint));

    if (response.statusCode != 200) {
      throw Exception('Unable to load cart (${response.statusCode})');
    }

    return _parseCartResponse(response.body);
  }

  Future<Cart> addProduct({
    required Product product,
    int quantity = 1,
    int userId = 1,
  }) async {
    final response = await http.post(
      Uri.parse(addToCartEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {'id': product.id, 'quantity': quantity},
        ],
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Unable to add product to cart (${response.statusCode})');
    }

    return _parseCartResponse(response.body);
  }

  Cart _parseCartResponse(String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final carts = data['carts'];
    if (carts is List && carts.isNotEmpty) {
      return Cart.fromJson(carts.first as Map<String, dynamic>);
    }
    return Cart.fromJson(data);
  }
}
