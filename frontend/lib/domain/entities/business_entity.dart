class BusinessEntity {
  final String uuid;
  final String businessName;
  final String plan;
  final bool isActive;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstin;
  final String? logoUrl;
  final DateTime? planExpiryDate;

  const BusinessEntity({
    required this.uuid,
    required this.businessName,
    required this.plan,
    required this.isActive,
    this.businessType,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.gstin,
    this.logoUrl,
    this.planExpiryDate,
  });
}
