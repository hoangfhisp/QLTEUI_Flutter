import 'package:flutter/material.dart';
import 'package:frontend_qlte/screens/client/home_screen.dart';
import 'package:frontend_qlte/screens/client/message/message_screen.dart';
import 'package:frontend_qlte/services/location_auto_sender.dart';
import 'package:frontend_qlte/utils/jwt_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationBarChildScreen extends StatefulWidget {
  const NavigationBarChildScreen({super.key});

  @override
  State<NavigationBarChildScreen> createState() => _NavigationBarChildScreenState();
}

class _NavigationBarChildScreenState extends State<NavigationBarChildScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  final LocationAutoSender _locationAutoSender = LocationAutoSender(); // 🔹 Tạo service gửi vị trí

  @override
  void initState() {
    super.initState();

    // ✅ Tự động gửi vị trí khi vừa đăng nhập
    _startAutoLocation();
    _widgetOptions = <Widget>[
      const HomeScreen(),
      const Center(child: Text('Trang Vị trí (Tự động gửi)', style: TextStyle(fontSize: 20))),
      ChangeNotifierProvider(
        create: (_) => MessageController(),
        child: const MessageScreen(),
      ),
      const Center(child: Text('Trang Cài Đặt (Demo)', style: TextStyle(fontSize: 20))),
    ];
  }

  Future<void> _startAutoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = JwtHelper.getUserId(token);
    try {
      // TODO: thay "child_001" bằng ID thực của trẻ khi login
      await _locationAutoSender.start(userId!);
      print("🚀 Bắt đầu chia sẻ vị trí tự động");
    } catch (e) {
      print("⚠️ Lỗi khởi động chia sẻ vị trí: $e");
    }
  }

  @override
  void dispose() {
    _locationAutoSender.stop(); // 🔹 Dừng khi thoát màn hình
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted_outlined),
            label: 'Bản tin',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            label: 'Vị trí',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Message',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Cài đặt',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
