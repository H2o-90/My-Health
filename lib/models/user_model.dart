import 'dart:convert';

class UserModel {
  final String fullName;
  final String email;
  final String gender; // 'Masculino', 'Femenino', 'Otro'
  final String passwordHash;
  final bool biometricEnabled;

  const UserModel({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.passwordHash,
    this.biometricEnabled = false,
  });

  /// Longitud de zancada estimada en metros según el sexo del usuario
  double get strideLengthMeters {
    switch (gender) {
      case 'Masculino':
        return 0.78;
      case 'Femenino':
        return 0.70;
      default:
        return 0.74;
    }
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? gender,
    String? passwordHash,
    bool? biometricEnabled,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      passwordHash: passwordHash ?? this.passwordHash,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'gender': gender,
      'passwordHash': passwordHash,
      'biometricEnabled': biometricEnabled,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      gender: map['gender'] ?? 'Otro',
      passwordHash: map['passwordHash'] ?? '',
      biometricEnabled: map['biometricEnabled'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}