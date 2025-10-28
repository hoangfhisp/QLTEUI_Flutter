import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_info_model.dart';
import '../../services/user_service.dart';
import '../../config/config_url.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  late Future<List<UserInfoModel>> _futureUsers;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("jwt_token");
    if (_token == null) return;
    setState(() {
      _futureUsers = UserService.getAllUsers(token: _token!);
    });
  }

  /// 🧩 Hiển thị ảnh đại diện
  String _buildAvatarUrl(String? avatarND) {
    if (avatarND == null || avatarND.isEmpty) {
      return "https://placehold.co/100x100?text=User";
    }

    // Nếu backend trả về full URL thì giữ nguyên
    if (avatarND.startsWith("http")) return avatarND;

    // Nếu trả về tương đối, ghép domain backend
    final base = Config_URL.baseUrl.replaceFirst("/api/", "");
    final fixedUrl = "$base$avatarND".replaceAll("//uploads", "/uploads");

    print("🖼️ [AdminUserScreen] Avatar URL: $fixedUrl");
    return fixedUrl;
  }

  /// 🧩 Xem chi tiết User
  void _showUserDetail(UserInfoModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("👤 Thông tin người dùng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_buildAvatarUrl(user.avatarND)),
              radius: 40,
            ),
            const SizedBox(height: 10),
            Text("🆔 ID: ${user.id}"),
            Text("📧 Email: ${user.email ?? 'Chưa có'}"),
            Text("👤 Tên: ${user.nameND ?? '(Trống)'}"),
            Text("📱 SĐT: ${user.phoneNumber ?? '(Trống)'}"),
            Text("🚻 Giới tính: ${user.gioiTinh == 1 ? 'Nam' : user.gioiTinh == 0 ? 'Nữ' : 'Khác'}"),
            Text("🕓 Tạo: ${user.thoiGianTao?.toLocal() ?? '-'}"),
            if (user.moTa?.isNotEmpty == true)
              Text("💬 Mô tả: ${user.moTa}"),
            Text("🎭 Roles: ${user.roles.join(', ')}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  /// ✏️ Cập nhật thông tin người dùng
  Future<void> _showEditUserDialog(UserInfoModel user) async {
    final nameController = TextEditingController(text: user.nameND ?? "");
    final phoneController = TextEditingController(text: user.phoneNumber ?? "");
    final descController = TextEditingController(text: user.moTa ?? "");
    int? gioiTinh = user.gioiTinh;
    File? selectedAvatar;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("✏️ Cập nhật người dùng"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setStateDialog(() => selectedAvatar = File(picked.path));
                    }
                  },
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage: selectedAvatar != null
                        ? FileImage(selectedAvatar!)
                        : NetworkImage(_buildAvatarUrl(user.avatarND)) as ImageProvider,
                    child: const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.camera_alt, size: 22, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên người dùng"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                ),
                DropdownButtonFormField<int>(
                  value: gioiTinh,
                  decoration: const InputDecoration(labelText: "Giới tính"),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text("Nam")),
                    DropdownMenuItem(value: 0, child: Text("Nữ")),
                    DropdownMenuItem(value: 2, child: Text("Khác")),
                  ],
                  onChanged: (v) => setStateDialog(() => gioiTinh = v),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Mô tả"),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                if (_token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Phiên đăng nhập đã hết.")),
                  );
                  return;
                }

                final result = await UserService.updateInfoUser(
                  userId: user.id,
                  userName: user.userName ?? "",
                  nameND: nameController.text.trim(),
                  gioiTinh: gioiTinh,
                  moTa: descController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  avatarPath: selectedAvatar?.path,
                  token: _token!,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result["message"] ?? "Đã cập nhật")),
                  );
                  _loadUsers();
                }
              },
              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🗑️ Xóa user
  Future<void> _deleteUser(UserInfoModel user) async {
    if (_token == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa người dùng"),
        content: Text("Bạn có chắc muốn xóa ${user.nameND ?? 'người dùng này'}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      final result = await UserService.deleteUser(userId: user.id, token: _token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"] ?? "Đã xóa")),
        );
        _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👥 Quản lý người dùng"),
        backgroundColor: Colors.indigo,
      ),
      body: FutureBuilder<List<UserInfoModel>>(
        future: _futureUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("❌ Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có người dùng nào."));
          }

          final users = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _loadUsers,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(_buildAvatarUrl(user.avatarND)),
                      radius: 25,
                    ),
                    title: Text(user.nameND ?? "Không rõ"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${user.email ?? 'Không có'}"),
                        Text("Vai trò: ${user.roles.join(', ')}"),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _showUserDetail(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showEditUserDialog(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
