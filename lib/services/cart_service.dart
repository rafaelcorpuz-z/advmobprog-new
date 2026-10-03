import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';
import '../models/product_model.dart';
class CartService {
 // Enhancement 3: getById-style fetch — pulls cart for a single user
 // instead of all carts, using GET /carts/user/{userId}.
 Future<Cart?> getCartByUserId() async {
   final response = await http.get(Uri.parse(cartEndpoint));
   if (response.statusCode == 200) {
     final Map<String, dynamic> data = jsonDecode(response.body);
     final List carts = data['carts'] ?? [];
     if (carts.isEmpty) return null;
     // dummyjson returns a list even when scoped to one user; take the first.
     return Cart.fromJson(carts.first);
   } else {
     throw Exception('Failed to load cart');
   }
 }
 // Enhancement 3: add to cart via POST /carts/add, passing product => cart
 // values (userId, product id, quantity).
 Future<Cart> addProduct({required Product product, int quantity = 1}) async {
   final response = await http.post(
     Uri.parse(addToCartEndpoint),
     headers: {'Content-Type': 'application/json'},
     body: jsonEncode({
       'userId': 1,
       'products': [
         {'id': product.id, 'quantity': quantity},
       ],
     }),
   );
   if (response.statusCode == 200 || response.statusCode == 201) {
     final Map<String, dynamic> data = jsonDecode(response.body);
     return Cart.fromJson(data);
   } else {
     throw Exception('Failed to add product to cart');
   }
 }
}