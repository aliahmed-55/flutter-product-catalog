class Category {
  const Category({required this.slug, required this.name, required this.url});

  final String slug;
  final String name;
  final String url;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      slug: json['slug'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }
}
