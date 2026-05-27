class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.description,
    this.parentId,
  });

  final String id;
  final String name;
  final String slug;
  final String type;
  final String description;
  final String? parentId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? 'product',
      description: json['description'] as String? ?? '',
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
    );
  }
}
