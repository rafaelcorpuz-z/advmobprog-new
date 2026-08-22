import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse(productsEndpoint));

    if (response.statusCode != 200) {
      throw Exception('Unable to load products (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>? ?? const [];
    return products
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}
