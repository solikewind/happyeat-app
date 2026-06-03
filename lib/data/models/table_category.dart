class TableCategoryItem {
  TableCategoryItem({
    required this.id,
    required this.name,
    this.description,
  });

  final String id;
  final String name;
  final String? description;

  factory TableCategoryItem.fromJson(Map<String, dynamic> json) {
    return TableCategoryItem(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      description: json['description'] as String?,
    );
  }
}
