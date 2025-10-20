import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userEmail;
  String? _role;
  bool _isExpired = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndPets();
  }

  Future<void> _loadTokenAndPets() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token != null) {
      final decodedToken = JwtDecoder.decode(token);
      setState(() {
        _token = token;
        _userEmail = decodedToken["http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"] ?? "Không rõ";
        _role = decodedToken["http://schemas.microsoft.com/ws/2008/06/identity/claims/role"] ?? "Không rõ";
        _isExpired = JwtDecoder.isExpired(token);
      });

    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text("🐾 Trang chủ người dùng"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _userEmail == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Thông tin người dùng
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Email: $_userEmail", style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🐾 Section gợi ý thú cưng phù hợp
            const Text(
              "🐶 Gợi ý thú cưng phù hợp với bạn",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 20),

            const Text(
              "Tính năng chính",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 🧩 Grid 3 tính năng chính
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildFeatureCard(
                    icon: Icons.pets,
                    title: "Quản lý thú cưng",
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.pushNamed(context, '/pets'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.assignment,
                    title: "Yêu cầu nhận nuôi",
                    color: Colors.lightGreen,
                    onTap: () => Navigator.pushNamed(context, '/adoptionrequests'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.vaccines,
                    title: "Lịch tiêm phòng",
                    color: Colors.lightBlue,
                    onTap: () => Navigator.pushNamed(context, '/vaccinationschedule'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.info_outline,
                    title: "Thông tin người dùng",
                    color: Colors.deepPurpleAccent,
                    onTap: () => Navigator.pushNamed(context, '/userinfo'),
                  ),
                  _buildFeatureCard(
                    icon: Icons.chat_bubble_outline,
                    title: "Đoạn chat",
                    color: Colors.orangeAccent,
                    onTap: () => Navigator.pushNamed(context, '/chatmassagelist'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
