class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.description,
    this.parentId,
    this.active = true,
    this.sortOrder = 0,
    this.formTemplate = 'standard',
  });

  final String id;
  final String name;
  final String slug;
  final String type;
  final String description;
  final String? parentId;
  final bool active;
  final int sortOrder;
  final String formTemplate;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      type: json['type'] as String? ?? 'product',
      description: json['description'] as String? ?? '',
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      active: json['active'] != false,
      sortOrder:
          (json['sortOrder'] as num? ?? json['sort_order'] as num?)?.toInt() ??
              0,
      formTemplate: json['formTemplate'] as String? ??
          json['form_template'] as String? ??
          'standard',
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'description': description,
      'parent_id': parentId,
      'active': active,
      'sort_order': sortOrder,
      'form_template': formTemplate,
    };
  }
}
