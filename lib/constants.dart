import 'package:flutter_dotenv/flutter_dotenv.dart';

final String apiHost =
    dotenv.env['DUMMYJSON_BASE_URL'] ?? 'https://dummyjson.com';
final String productsEndpoint = '$apiHost/products';
final String cartEndpoint = '$apiHost/carts/user/1';
final String addToCartEndpoint = '$apiHost/carts/add';
