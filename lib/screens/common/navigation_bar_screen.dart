import 'package:flutter/material.dart';
import 'package:frontend_qlte/screens/client/child/children_list_screen.dart';
import 'package:frontend_qlte/screens/client/home_screen.dart';
import 'package:frontend_qlte/screens/client/message/message_screen.dart';
import 'package:frontend_qlte/services/child_service.dart';
import 'package:frontend_qlte/services/signalr_service.dart';
import 'package:frontend_qlte/utils/jwt_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationBarScreen extends StatefulWidget {
  const NavigationBarScreen({super.key});

  @override
  State<NavigationBarScreen> createState() => _NavigationBarScreenState();
}

class _NavigationBarScreenState extends State<NavigationBarScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  final SignalRService _signalRService = SignalRService();

  @override
  void initState() {
    super.initState();

    _widgetOptions = <Widget>[
      const HomeScreen(),
      const ChildrenListScreen(),
      ChangeNotifierProvider(
        create: (_) => MessageController(),
        child: const MessageScreen(),
      ),
      const Center(
        child: Text('Trang Cài Đặt (Demo)', style: TextStyle(fontSize: 20)),
      ),
    ];
    _initSignalRGroup();
  }

  Future<void> _initSignalRGroup() async {
    try {
      // 🔹 Lấy token & userId
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";
      final userId = JwtHelper.getUserId(token);

      // 🔹 Kết nối SignalR
      await _signalRService.connect();

      // 🔹 Lấy danh sách con của phụ huynh
      final childrenRes = await ChildService.getChildrenByUserId(
        userId!,
        token,
      );
      if (childrenRes.status && childrenRes.data.isNotEmpty) {
        for (var child in childrenRes.data) {
          await _signalRService.joinChildGroup(child.childId);
        }
      }

      // 🔹 Lắng nghe cảnh báo khi trẻ ra khỏi vùng an toàn
      _signalRService.onChildLeftSafeZone((data) {
        final tenTre = data['tenTre'];
        final message = data['message'];
        _showWarningDialog("$tenTre cảnh báo!", message);
      });

      print("✅ Đã kết nối SignalR và join group các con");
    } catch (e) {
      print("⚠️ Lỗi khi join group SignalR: $e");
    }
  }

  void _showWarningDialog(String title, String content) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
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
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
