import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend_qlte/screens/client/child/home_children_screen.dart';
import 'package:frontend_qlte/services/location_auto_sender.dart';
import 'package:frontend_qlte/services/signalr_service.dart';
import 'package:frontend_qlte/services/device_info_service.dart';
import 'package:frontend_qlte/utils/jwt_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class NavigationBarChildScreen extends StatefulWidget {
  const NavigationBarChildScreen({super.key});

  @override
  State<NavigationBarChildScreen> createState() =>
      _NavigationBarChildScreenState();
}

class _NavigationBarChildScreenState extends State<NavigationBarChildScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;
  final LocationAutoSender _locationAutoSender = LocationAutoSender();
  final SignalRService _signalRService = SignalRService();

  bool _isLocked = false;
  Timer? _statusTimer;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startAutoLocation();
    _initSignalR();
    _startAutoUpdateStatus(); // ✅ auto cập nhật pin / online định kỳ

    // 🔁 Hiệu ứng rung icon khi bị khóa
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    // Các tab chính
    _widgetOptions = <Widget>[
      const HomeChildrenScreen(),
      const Center(
        child: Text('📍 Theo dõi vị trí (Tự động gửi)', style: TextStyle(fontSize: 18)),
      ),
      const Center(
        child: Text('💬 Tin nhắn với phụ huynh', style: TextStyle(fontSize: 18)),
      ),
      const Center(
        child: Text('⚙️ Cài đặt tài khoản', style: TextStyle(fontSize: 18)),
      ),
    ];
  }

  // 🛰️ Khởi tạo và lắng nghe SignalR
  Future<void> _initSignalR() async {
    try {
      await _signalRService.connectDeviceHub();

      // 🔒 Nhận sự kiện khoá thiết bị
      _signalRService.onDeviceLocked((data) async {
        setState(() => _isLocked = true);

        // rung nhẹ khi bị khoá
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 400, 150, 400]);
        }
      });

      // 🔓 Nhận sự kiện mở khoá thiết bị
      _signalRService.onDeviceUnlocked((data) {
        setState(() => _isLocked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Thiết bị đã được mở khoá."),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      print("⚠️ Lỗi kết nối DeviceHub: $e");
    }
  }

  // 📡 Bắt đầu chia sẻ vị trí tự động
  Future<void> _startAutoLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userId = JwtHelper.getUserId(token);
    try {
      await _locationAutoSender.start(userId!);
      print("🚀 Bắt đầu chia sẻ vị trí tự động");
    } catch (e) {
      print("⚠️ Lỗi khởi động chia sẻ vị trí: $e");
    }
  }

  // 🔋 Gửi thông tin trạng thái thiết bị định kỳ
  void _startAutoUpdateStatus() {
    _stopAutoUpdateStatus(); // dừng nếu đã có timer cũ

    // ⚡ Gửi cập nhật ngay lập tức khi app khởi động
    _updateStatusNow();

    // ⏱️ Sau đó gửi định kỳ mỗi 5 phút
    _statusTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateStatusNow();
    });
  }

  // 📤 Gửi thông tin pin + online hiện tại
  Future<void> _updateStatusNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString("device_id");
      if (deviceId == null) {
        print("⚠️ Không tìm thấy device_id trong SharedPreferences");
        return;
      }

      final randomPin = 60 + Random().nextInt(40); // 60–99%
      await DeviceInfoService.updateStatus(
        deviceId: deviceId,
        pin: randomPin,
        online: true,
      );

      print("📡 [Auto] Gửi trạng thái thiết bị (pin=$randomPin%) cho deviceId=$deviceId");
    } catch (e) {
      print("⚠️ [Auto] Lỗi khi cập nhật trạng thái thiết bị: $e");
    }
  }

  void _stopAutoUpdateStatus() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  @override
  void dispose() {
    _locationAutoSender.stop();
    _stopAutoUpdateStatus(); // ✅ dừng timer khi thoát
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_isLocked) return; // chặn thao tác khi bị khoá
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('🧒 KidGuardian - Trẻ em'),
            backgroundColor: Colors.teal,
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('jwt_token');
                  await prefs.remove('device_id');
                  await prefs.remove('child_id');

                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/login');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Đã đăng xuất thành công."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _widgetOptions[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.teal,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.my_location),
                label: 'Vị trí',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message_outlined),
                label: 'Tin nhắn',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Cài đặt',
              ),
            ],
          ),
        ),

        // 🟥 Overlay toàn màn hình khi bị khoá
        if (_isLocked)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: SafeArea(
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_rounded, size: 120, color: Colors.redAccent),
                        SizedBox(height: 30),
                        Text(
                          "Thiết bị của bạn đã bị khóa",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Phụ huynh đã tạm thời khóa thiết bị này.\nVui lòng chờ mở khóa để tiếp tục sử dụng.",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
