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
      final result = await Auth.login(account, password);

      if (!mounted) return;

      if (result["success"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("jwt_token", result["token"]);

        final decoded = result["decodedToken"];
        final role = decoded["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"];
        final email = decoded["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xin chào $email — Vai trò: $role")),
        );

        if (role == "Admin") {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() => _errorMessage = result["message"] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      setState(() => _errorMessage = "Lỗi kết nối: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.teal.shade600; // màu chủ đạo KidGuardian

    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ✅ Logo biểu tượng trẻ em / gia đình
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
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              // Ô nhập tài khoản
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

              // Ô nhập mật khẩu
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

              // Hiển thị lỗi
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Nút đăng nhập
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

              // Nút đăng ký
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

              // Nút quên mật khẩu
              TextButton(
                onPressed: () {
                  // Tạm thời bỏ trống
                },
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
