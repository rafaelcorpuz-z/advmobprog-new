class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    required this.discountPercentage,
    required this.discountedPrice,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final double discountPercentage;
  final double discountedPrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    final double price = (json['price'] as num?)?.toDouble() ?? 0;
    final double discountPercentage =
        (json['discountPercentage'] as num?)?.toDouble() ?? 0;
    final double discountedPrice =
        price * (1 - (discountPercentage / 100));

    return Product(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled product',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      price: price,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      discountPercentage: discountPercentage,
      discountedPrice: discountedPrice,
    );
  }
}
