import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend_qlte/models/device_info_model.dart';
import 'package:frontend_qlte/services/device_info_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceDetailChildScreen extends StatefulWidget {
  final DeviceInfoModel device;

  const DeviceDetailChildScreen({
    super.key,
    required this.device,
  });

  @override
  State<DeviceDetailChildScreen> createState() => _DeviceDetailChildScreenState();
}

class _DeviceDetailChildScreenState extends State<DeviceDetailChildScreen> {
  bool _loading = false;
  bool _isTracking = false;
  bool _isLocked = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _isTracking = widget.device.isTracking;
    _isLocked = widget.device.isLocked;
    if (_isTracking) _startAutoUpdateStatus();
  }

  /// 🧩 Bật / Tắt tracking
  Future<void> _toggleTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || widget.device.childId == null) return;

    setState(() => _loading = true);

    try {
      final result = await DeviceInfoService.setTracking(
        widget.device.childId!,
        !_isTracking,
        token,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor:
          result['success'] ? Colors.teal : Colors.redAccent,
        ),
      );

      if (result['success']) {
        setState(() => _isTracking = !_isTracking);
        if (_isTracking) {
          _startAutoUpdateStatus();
        } else {
          _stopAutoUpdateStatus();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Lỗi bật/tắt theo dõi: $e")),
      );
    }

    setState(() => _loading = false);
  }

  /// 🧩 Khoá / Mở khoá thiết bị
  Future<void> _toggleLock() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || widget.device.childId == null) return;

    setState(() => _loading = true);

    try {
      final result = _isLocked
          ? await DeviceInfoService.unlockDevice(widget.device.childId!, token)
          : await DeviceInfoService.lockDevice(widget.device.childId!, token);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor:
          result['success'] ? Colors.blue : Colors.redAccent,
        ),
      );

      if (result['success']) {
        setState(() => _isLocked = !_isLocked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Lỗi thay đổi trạng thái thiết bị: $e")),
      );
    }

    setState(() => _loading = false);
  }

  /// 🕐 Tự động gửi trạng thái pin / online (mỗi 5 phút)
  void _startAutoUpdateStatus() {
    _stopAutoUpdateStatus(); // dừng nếu có timer cũ
    _statusTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!mounted) return; // nếu người dùng đã thoát màn hình
      try {
        final randomPin = 60 + Random().nextInt(40); // 60–99%
        await DeviceInfoService.updateStatus(
          deviceId: widget.device.deviceId ?? "",
          pin: randomPin,
          online: true,
        );
        // ignore: avoid_print
        print("📡 [Auto] Đã cập nhật trạng thái thiết bị ${widget.device.tenThietBi}");
      } catch (e) {
        // ignore: avoid_print
        print("⚠️ [Auto] Lỗi cập nhật: $e");
      }
    });
  }

  /// 🧩 Dừng auto update
  void _stopAutoUpdateStatus() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  @override
  void dispose() {
    _stopAutoUpdateStatus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.tenThietBi ?? "Chi tiết thiết bị"),
        backgroundColor: Colors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.phone_android,
                size: 100,
                color:
                device.trangThaiOnline ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Text("📱 Tên thiết bị: ${device.tenThietBi ?? '--'}",
                style: const TextStyle(fontSize: 18)),
            Text("IMEI: ${device.imei ?? '--'}"),
            Text("Pin: ${device.pin ?? '--'}%"),
            const Divider(height: 30),

            // 🛰️ Theo dõi định kỳ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Theo dõi định kỳ (5 phút/lần)",
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _isTracking,
                  onChanged: (_) => _toggleTracking(),
                  activeColor: Colors.teal,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔒 Khoá / Mở khoá thiết bị
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Trạng thái thiết bị",
                  style: TextStyle(fontSize: 16),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleLock,
                  icon: Icon(
                    _isLocked ? Icons.lock_open : Icons.lock_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isLocked ? "Mở khoá" : "Khoá thiết bị",
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked
                        ? Colors.green
                        : Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
