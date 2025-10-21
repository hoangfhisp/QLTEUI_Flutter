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
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      nameND: json['nameND'] as String,
      gioiTinh: json['gioiTinh'] as int,
      mota: json['mota'] as String?,
      avatarND: json['avatarND'] as String,
      typeLogin: json['typeLogin'] as String,
      role: json['role'] as String,
      thoiGianCapNhat: DateTime.parse(json['thoiGianCapNhat'] as String),
      thoiGianTao: DateTime.parse(json['thoiGianTao'] as String),
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
