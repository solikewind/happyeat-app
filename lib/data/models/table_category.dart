class TableCategoryItem {
  TableCategoryItem({
    required this.id,
    required this.name,
    this.description,
    this.sort = 0,
  });

  final String id;
  final String name;
  final String? description;
  final int sort;

  factory TableCategoryItem.fromJson(Map<String, dynamic> json) {
    return TableCategoryItem(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      description: json['description'] as String?,
      sort: (json['sort'] as num?)?.toInt() ?? 0,
    );
  }
}
