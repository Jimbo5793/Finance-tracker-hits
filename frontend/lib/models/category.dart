class Category {
  final int id;
  final String name;
  final String icon;
  final String kind;
  final bool? mandatory;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    this.mandatory,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    icon: json['icon'] as String,
    kind: json['kind'] as String,
    mandatory: json['mandatory'] as bool?,
  );
}
