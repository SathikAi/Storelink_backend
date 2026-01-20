import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    super.id,
    required super.uuid,
    required super.businessId,
    required super.name,
    super.description,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      uuid: json['uuid'],
      businessId: json['business_id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'business_id': businessId,
      'name': name,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CategoryCreateRequest {
  final String name;
  final String? description;
  final bool isActive;

  CategoryCreateRequest({
    required this.name,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
    };
  }
}

class CategoryUpdateRequest {
  final String? name;
  final String? description;
  final bool? isActive;

  CategoryUpdateRequest({
    this.name,
    this.description,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isActive != null) 'is_active': isActive,
    };
  }
}
