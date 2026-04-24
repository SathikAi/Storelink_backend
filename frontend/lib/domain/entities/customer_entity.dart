class CustomerEntity {
  final String uuid;
  final int businessId;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    required this.uuid,
    required this.businessId,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress {
    final parts = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
      if (pincode != null && pincode!.isNotEmpty) pincode,
    ];
    return parts.isEmpty ? 'No address provided' : parts.join(', ');
  }

  bool get hasCompleteAddress =>
      address != null && city != null && state != null && pincode != null;

  String get displayPhone => phone.length == 10 ? '+91 $phone' : phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CustomerEntity && other.uuid == uuid);

  @override
  int get hashCode => uuid.hashCode;
}
