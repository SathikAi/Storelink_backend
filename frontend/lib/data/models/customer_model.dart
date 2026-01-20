import '../../domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.uuid,
    required super.businessId,
    required super.name,
    required super.phone,
    super.email,
    super.address,
    super.city,
    super.state,
    super.pincode,
    super.notes,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      uuid: json['uuid'] as String,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CustomerCreateRequest {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? notes;
  final bool isActive;

  const CustomerCreateRequest({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['phone'] = phone;
    if (email != null && email!.isNotEmpty) data['email'] = email;
    if (address != null && address!.isNotEmpty) data['address'] = address;
    if (city != null && city!.isNotEmpty) data['city'] = city;
    if (state != null && state!.isNotEmpty) data['state'] = state;
    if (pincode != null && pincode!.isNotEmpty) data['pincode'] = pincode;
    if (notes != null && notes!.isNotEmpty) data['notes'] = notes;
    data['is_active'] = isActive;
    return data;
  }
}

class CustomerUpdateRequest {
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? notes;
  final bool? isActive;

  const CustomerUpdateRequest({
    this.name,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.notes,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (address != null) data['address'] = address;
    if (city != null) data['city'] = city;
    if (state != null) data['state'] = state;
    if (pincode != null) data['pincode'] = pincode;
    if (notes != null) data['notes'] = notes;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
