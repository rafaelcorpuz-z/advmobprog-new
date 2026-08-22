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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled product',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] as int? ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
      images: (json['images'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }
}
