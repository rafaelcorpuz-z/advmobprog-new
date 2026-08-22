class Cart {
  final int id;
  final List<CartProduct> products;
  final double total;
  final double discountedTotal;
  final int userId;
  final int totalProducts;
  final int totalQuantity;

  Cart({
    required this.id,
    required this.products,
    required this.total,
    required this.discountedTotal,
    required this.userId,
    required this.totalProducts,
    required this.totalQuantity,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: _asInt(json['id']),
      products: (json['products'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CartProduct.fromJson)
          .toList(),
      total: _asDouble(json['total']),
      discountedTotal: _asDouble(json['discountedTotal']),
      userId: _asInt(json['userId']),
      totalProducts: _asInt(json['totalProducts']),
      totalQuantity: _asInt(json['totalQuantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products.map((product) => product.toJson()).toList(),
      'total': total,
      'discountedTotal': discountedTotal,
      'userId': userId,
      'totalProducts': totalProducts,
      'totalQuantity': totalQuantity,
    };
  }
}

class CartProduct {
  final int id;
  final String title;
  final double price;
  final int quantity;
  final double total;
  final double discountPercentage;
  final double discountedPrice;
  final String thumbnail;

  CartProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.total,
    required this.discountPercentage,
    required this.discountedPrice,
    required this.thumbnail,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      id: _asInt(json['id']),
      title: json['title'] as String? ?? 'Untitled product',
      price: _asDouble(json['price']),
      quantity: _asInt(json['quantity']),
      total: _asDouble(json['total']),
      discountPercentage: _asDouble(json['discountPercentage']),
      discountedPrice: _asDouble(json['discountedPrice']),
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'total': total,
      'discountPercentage': discountPercentage,
      'discountedPrice': discountedPrice,
      'thumbnail': thumbnail,
    };
  }
}

double _asDouble(Object? value) => value is num ? value.toDouble() : 0;

int _asInt(Object? value) => value is num ? value.toInt() : 0;
