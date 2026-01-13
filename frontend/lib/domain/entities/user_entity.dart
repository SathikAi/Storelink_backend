class UserEntity {
  final String uuid;
  final String phone;
  final String? email;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;

  const UserEntity({
    required this.uuid,
    required this.phone,
    this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
  });
}
