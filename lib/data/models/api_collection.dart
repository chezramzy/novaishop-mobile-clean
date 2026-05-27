class ApiCollection<T> {
  const ApiCollection({
    required this.items,
    required this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  final List<T> items;
  final int total;
  final int? page;
  final int? pageSize;
  final int? totalPages;

  factory ApiCollection.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItemJson,
  ) {
    final rawItems = json['items'];
    return ApiCollection<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => fromItemJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt(),
      pageSize: (json['pageSize'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
    );
  }
}
