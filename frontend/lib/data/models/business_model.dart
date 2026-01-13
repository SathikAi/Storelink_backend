import '../../domain/entities/business_entity.dart';

class BusinessModel extends BusinessEntity {
  const BusinessModel({
    required super.uuid,
    required super.businessName,
    required super.plan,
    required super.isActive,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      uuid: json['uuid'] as String,
      businessName: json['business_name'] as String,
      plan: json['plan'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'business_name': businessName,
      'plan': plan,
      'is_active': isActive,
    };
  }
}
