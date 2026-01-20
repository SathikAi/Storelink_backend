class CategoryEntity {
  final int? id;
  final String uuid;
  final int businessId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    this.id,
    required this.uuid,
    required this.businessId,
    required this.name,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
