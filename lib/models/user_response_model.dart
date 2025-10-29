class UserResponseModel {
  final String userId;
  final String userName;
  final String email;
  final String phoneNumber;
  final String nameND;
  final int gioiTinh;
  final String? mota;
  final String avatarND;
  final String typeLogin;
  final String role;
  final DateTime thoiGianCapNhat;
  final DateTime thoiGianTao;

  UserResponseModel({
    required this.userId,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.nameND,
    required this.gioiTinh,
    this.mota,
    required this.avatarND,
    required this.typeLogin,
    required this.role,
    required this.thoiGianCapNhat,
    required this.thoiGianTao,
  });

  factory UserResponseModel.fromJson(Map<String, dynamic> json) {
    return UserResponseModel(
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      nameND: (json['nameND'] ?? 'Không rõ').toString(),
      gioiTinh: json['gioiTinh'] is int ? json['gioiTinh'] : 2,
      mota: json['mota']?.toString(),
      avatarND: (json['avatarND'] ?? '').toString(),
      typeLogin: (json['typeLogin'] ?? 'Local').toString(),
      role: (json['role'] ?? 'User').toString(),
      thoiGianCapNhat: DateTime.tryParse(json['thoiGianCapNhat'] ?? '') ?? DateTime.now(),
      thoiGianTao: DateTime.tryParse(json['thoiGianTao'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'phoneNumber': phoneNumber,
      'nameND': nameND,
      'gioiTinh': gioiTinh,
      'mota': mota,
      'avatarND': avatarND,
      'typeLogin': typeLogin,
      'role': role,
      'thoiGianCapNhat': thoiGianCapNhat.toIso8601String(),
      'thoiGianTao': thoiGianTao.toIso8601String(),
    };
  }
}
