/// Data model for a spending/income category.
class Category {
  final String id;
  final String userId;
  final String name;
  final String icon; // Material icon name string
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'icon': icon,
        'is_default': isDefault,
      };

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
