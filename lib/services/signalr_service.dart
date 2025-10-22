import 'package:frontend_qlte/config/config_url.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  HubConnection? _connection;

  Future<void> connect() async {
    if (_connection != null && _connection!.state == HubConnectionState.Connected) return;

    _connection = HubConnectionBuilder()
        .withUrl("${Config_URL.urlServer}locationHub")
        .build();

    await _connection!.start();
    print("✅ Connected to SignalR Hub");
  }

  // 👉 Dành cho Child: gửi vị trí hiện tại
  Future<void> sendLocation(String childId, double lat, double lng) async {
    if (_connection == null) return;
    try {
      await _connection!.invoke("SendLocation", args: [childId, lat, lng]);
      print("📤 Sent location: ($lat, $lng)");
    } catch (e) {
      print("⚠️ Error sending location: $e");
    }
  }

  // 👉 Dành cho Parent: join group childId để chỉ nhận dữ liệu child đó
  Future<void> joinChildGroup(String childId) async {
    if (_connection == null) return;
    try {
      await _connection!.invoke("JoinChildGroup", args: [childId]);
      print("✅ Joined group child-$childId");
    } catch (e) {
      print("⚠️ Error joining group: $e");
    }
  }

  // 👉 Nhận dữ liệu từ child
  void onReceiveLocation(Function(String, double, double) onUpdate) {
    _connection?.on("ReceiveChildLocation", (args) {
      final id = args![0] as String;
      final lat = args[1] as double;
      final lng = args[2] as double;
      onUpdate(id, lat, lng);
    });
  }
}
