import 'package:flutter/material.dart';
import 'package:frontend_qlte/services/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    if (account.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🔹 Gọi API đăng nhập
      final result = await Auth.login(account, password);

      if (!mounted) return;

      if (result["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", result["token"]);

        // ✅ Giải mã token
        final decoded = result["decodedToken"];
        final role = decoded["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"];
        final email = decoded["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"];

        // 🎉 Hiển thị thông báo chào mừng
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xin chào $email — Vai trò: $role")),
        );

        // 🧒 Nếu là tài khoản trẻ em → đợi đến khi có child_id
        if (role == "Children") {
          String? childId;
          for (int i = 0; i < 5; i++) {
            // đợi child_id từ AuthService (đã gọi API GetChildByUserId)
            childId = prefs.getString("child_id");
            if (childId != null && childId.isNotEmpty) break;
            await Future.delayed(const Duration(milliseconds: 500));
          }

          if (childId == null || childId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Không thể lấy thông tin Child. Vui lòng thử lại."),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() => _isLoading = false);
            return;
          }

          print("✅ Child ID loaded: $childId");
        }

        // ✅ Điều hướng theo vai trò
        if (role == "Admin") {
          Navigator.pushReplacementNamed(context, '/admin');
        } else if (role == "Parent") {
          Navigator.pushReplacementNamed(context, '/navigationbar');
        } else if (role == "Children") {
          Navigator.pushReplacementNamed(context, '/navigationbarchild');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // ⚠️ Nếu API trả về lỗi (status=false)
        final msg = result["message"] ?? result["msg"] ?? "Đăng nhập thất bại, vui lòng thử lại.";
        setState(() => _errorMessage = msg);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = "Đăng nhập thất bại: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lỗi: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600; // 🎨 Màu chủ đạo KidGuardian

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Logo KidGuardian
              Icon(Icons.family_restroom, size: 90, color: themeColor),
              const SizedBox(height: 10),
              const Text(
                "Ứng dụng KidGuardian",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Bảo vệ & đồng hành cùng con yêu mỗi ngày",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // 🔹 Nhập tài khoản
              TextField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: "Tài khoản / Email",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 🔹 Nhập mật khẩu
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ⚠️ Hiển thị lỗi
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // 🔘 Nút đăng nhập
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Đăng nhập",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Nút đăng ký
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: Text(
                  "Chưa có tài khoản? Đăng ký ngay",
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 🔹 Nút quên mật khẩu
              TextButton(
                onPressed: () {},
                child: Text(
                  "Quên mật khẩu?",
                  style: TextStyle(color: themeColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
