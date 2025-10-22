import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend_qlte/services/signalr_service.dart';
import 'package:frontend_qlte/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapTrackingScreen extends StatefulWidget {
  final String childId; // nhận childId cần theo dõi

  const MapTrackingScreen({super.key, required this.childId});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  bool _showSafeZone = true;
  LatLng? _childPos;
  final LatLng safeCenter = LatLng(10.850503, 106.754150);
  final double safeRadius = 200;
  final SignalRService _signalRService = SignalRService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
    _initSignalR();
  }

  Future<void> _loadInitialLocation() async {
    try {
      // 🔹 Gọi API lấy vị trí mới nhất
      final token = await _getToken(); // Hàm lấy token từ SharedPreferences
      final res = await LocationService.getChildrenByUserId(widget.childId, token);

      if (res.status && res.data.isNotEmpty) {
        final latest = res.data.first;
        setState(() {
          _childPos = LatLng(latest.viDo, latest.kinhDo);
        });
      }
    } catch (e) {
      print("⚠️ Lỗi khi load location history: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    return token;
  }

  Future<void> _initSignalR() async {
    try {
      await _signalRService.connect();

      // Join group của childId (nếu backend hỗ trợ)
      try {
        await _signalRService.joinChildGroup(widget.childId);
      } catch (e) {
        print("⚠️ Không join được group: $e");
      }

      // Nhận dữ liệu từ SignalR
      _signalRService.onReceiveLocation((childId, lat, lng) {
        if (childId == widget.childId) {
          setState(() {
            _childPos = LatLng(lat, lng);
          });
        }
      });
    } catch (e) {
      print("⚠️ Lỗi khi kết nối SignalR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Theo dõi vị trí con")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _childPos ?? safeCenter,
                    initialZoom: 16,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    if (_showSafeZone)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: safeCenter,
                            useRadiusInMeter: true,
                            radius: safeRadius,
                            color: Colors.green.withOpacity(0.3),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: safeCenter,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.home, color: Colors.green, size: 36),
                        ),
                        if (_childPos != null)
                          Marker(
                            point: _childPos!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.person_pin_circle,
                                color: Colors.blue, size: 40),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showSafeZone ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => setState(() => _showSafeZone = true),
                        icon: const Icon(Icons.shield),
                        label: const Text("Vùng an toàn"),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_showSafeZone ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => setState(() => _showSafeZone = false),
                        icon: const Icon(Icons.warning),
                        label: const Text("Vùng nguy hiểm"),
                      ),
                    ],
                  ),
                ),
                if (_childPos != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "📡 Bé đang ở: ${_childPos!.latitude.toStringAsFixed(5)}, ${_childPos!.longitude.toStringAsFixed(5)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      "⏳ Đang chờ tín hiệu từ thiết bị của bé...",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
              ],
            ),
    );
  }
}
