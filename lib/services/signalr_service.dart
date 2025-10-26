import 'package:frontend_qlte/config/config_url.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:convert';
import 'dart:async';

class SignalRService {
  HubConnection? _connection;     // Location Hub
  HubConnection? _sosConnection;  // SOS Hub
  HubConnection? _deviceConnection; // Device Hub

  // 🔌 LocationHub
  Future<void> connect() async {
    if (_connection != null && _connection!.state == HubConnectionState.Connected) {
      print("⚡ Already connected to LocationHub");
      return;
    }

    _connection = HubConnectionBuilder()
        .withUrl("${Config_URL.urlServer}locationHub")
        .build();

    await _connection!.start();
    print("✅ Connected to LocationHub");
  }

  Future<void> sendLocation(String childId, double lat, double lng) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      print("⚠️ LocationHub chưa kết nối, đang thử reconnect...");
      await connect();
    }

    try {
      await _connection!.invoke("SendLocation", args: [childId, lat, lng]);
      print("📤 Sent location: ($lat, $lng)");
    } catch (e) {
      print("❌ Error sending location: $e");
    }
  }

  Future<void> joinChildGroup(String childId) async {
    if (_connection == null || _connection!.state != HubConnectionState.Connected) {
      print("⚠️ LocationHub chưa sẵn sàng, đang kết nối lại...");
      await connect();
    }

    try {
      await _connection!.invoke("JoinChildGroup", args: [childId]);
      print("✅ Joined location group for child-$childId");
    } catch (e) {
      print("⚠️ Error joining child group: $e");
    }
  }

  void onReceiveLocation(Function(String, double, double) onUpdate) {
    _connection?.on("ReceiveChildLocation", (args) {
      if (args == null || args.length < 3) return;
      final id = args[0] as String;
      final lat = args[1] as double;
      final lng = args[2] as double;
      print("📍 Location update from child-$id ($lat, $lng)");
      onUpdate(id, lat, lng);
    });
  }

  // 🚨 SOSHub
  Future<void> connectSOS({int maxRetries = 3}) async {
    int attempt = 0;
    bool connected = false;

    while (attempt < maxRetries && !connected) {
      attempt++;
      try {
        print("🔌 [SOSHub] Kết nối lần $attempt ...");

        if (_sosConnection != null && _sosConnection!.state == HubConnectionState.Connected) {
          print("⚡ SOSHub đã kết nối, bỏ qua reconnect.");
          connected = true;
          break;
        }

        final newConn = HubConnectionBuilder()
            .withUrl("${Config_URL.urlServer}sosHub")
            .build();

        _sosConnection = newConn;

        await Future.any([
          newConn.start()!,
          Future.delayed(const Duration(seconds: 4), () => throw TimeoutException("SOSHub start timed out")),
        ]);

        print("🚨 SOSHub connected thành công ở lần $attempt!");
        connected = true;

        // ✅ Đọc child_id từ SharedPreferences (đã lưu sau login)
        final prefs = await SharedPreferences.getInstance();
        final childId = prefs.getString("child_id");

        if (childId != null && childId.isNotEmpty) {
          await joinSOSGroup(childId);
          print("👨‍👧 Parent joined SOS group for child-$childId");
        } else {
          print("⚠️ Không tìm thấy child_id trong SharedPreferences (Parent chưa có con hoặc chưa đăng nhập).");
        }

      } catch (e) {
        print("⚠️ SOSHub kết nối thất bại lần $attempt: $e");
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (!connected) {
      print("❌ Không thể kết nối SOSHub sau $maxRetries lần thử.");
      throw Exception("Kết nối SOSHub thất bại sau nhiều lần thử.");
    }
  }

  Future<void> sendSOSRealtime(String message) async {
    if (_sosConnection == null || _sosConnection!.state != HubConnectionState.Connected) {
      print("⚠️ SOSHub chưa kết nối, đang thử reconnect...");
      await connectSOS();
    }

    try {
      await _sosConnection!.invoke("SendTest", args: [message]);
      print("📡 SOS realtime signal sent: $message");
    } catch (e) {
      print("❌ Lỗi khi gửi realtime SOS: $e");
    }
  }

  Future<void> joinSOSGroup(String childId) async {
    if (_sosConnection == null || _sosConnection!.state != HubConnectionState.Connected) {
      print("⚠️ SOSHub chưa sẵn sàng, đang kết nối lại...");
      await connectSOS();
    }

    try {
      await _sosConnection!.invoke("JoinGroup", args: [childId]);
      print("✅ Joined SOS group-$childId");
    } catch (e) {
      print("⚠️ Error joining SOS group: $e");
    }
  }

  // ✅ Hàm nhận realtime SOS (phiên bản backend mới)
  void onReceiveSOS(Function(Map<String, dynamic>) onSOS) {
    _sosConnection?.on("ReceiveSOS", (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;

      try {
        if (data is Map<String, dynamic>) {
          print("🚨 SOS received (map) → $data");
          onSOS(data);
        } else if (data is String) {
          final decoded = jsonDecode(data);
          print("🚨 SOS received (string) → $decoded");
          onSOS(Map<String, dynamic>.from(decoded));
        } else {
          print("⚠️ Unknown SOS data type: $data");
        }
      } catch (e) {
        print("❌ Error parsing SOS data: $e");
      }
    });
  }

  void onSOSUpdated(Function(Map<String, dynamic>) onUpdate) {
    _sosConnection?.on("SOSUpdated", (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        print("🔄 SOS Updated: $data");
        onUpdate(data);
      }
    });
  }

  void onSOSDeleted(Function(Map<String, dynamic>) onDelete) {
    _sosConnection?.on("SOSDeleted", (args) {
      if (args == null || args.isEmpty) return;
      final data = args.first;
      if (data is Map<String, dynamic>) {
        print("🗑️ SOS Deleted: $data");
        onDelete(data);
      }
    });
  }

  Future<void> disconnectAll() async {
    try {
      if (_connection != null && _connection!.state == HubConnectionState.Connected) {
        await _connection!.stop();
        print("🔌 Disconnected from LocationHub");
      }
      if (_sosConnection != null && _sosConnection!.state == HubConnectionState.Connected) {
        await _sosConnection!.stop();
        print("🔌 Disconnected from SOSHub");
      }
    } catch (e) {
      print("⚠️ Error disconnecting hubs: $e");
    }
  }

  // 🔌 Kết nối tới DeviceHub
  Future<void> connectDeviceHub({int maxRetries = 3}) async {
    int attempt = 0;
    bool connected = false;

    while (attempt < maxRetries && !connected) {
      attempt++;
      try {
        print("🔌 [DeviceHub] Kết nối lần $attempt ...");

        // ⚙️ Nếu đã có connection và đang connected thì bỏ qua
        if (_deviceConnection != null &&
            _deviceConnection!.state == HubConnectionState.Connected) {
          print("⚡ DeviceHub đã kết nối sẵn, bỏ qua reconnect.");
          connected = true;
          break;
        }

        // ✅ Tạo connection mới
        final connection = HubConnectionBuilder()
            .withUrl("${Config_URL.urlServer}deviceHub")
            .withAutomaticReconnect()
            .build();

        _deviceConnection = connection;

        // ⏳ Timeout sau 4s
        await Future.any([
          connection.start()!,
          Future.delayed(
            const Duration(seconds: 4),
                () => throw TimeoutException("DeviceHub start timed out"),
          ),
        ]);

        print("📡 DeviceHub connected thành công ở lần $attempt!");
        connected = true;

        // ✅ Lấy thông tin từ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        String? childId = prefs.getString("child_id");
        String? role = prefs.getString("role");

        // 🔁 Retry nhẹ nếu chưa có child_id (đợi AuthService lưu xong)
        int retry = 0;
        while ((childId == null || childId.isEmpty) && retry < 5) {
          await Future.delayed(const Duration(milliseconds: 500));
          childId = prefs.getString("child_id");
          retry++;
        }

        // 🎯 Kiểm tra role + childId
        if ((role == "Child" || role == "Children") &&
            childId != null &&
            childId.isNotEmpty) {
          await joinDeviceGroup(childId);
          print("✅ [DeviceHub] Child joined Device group-$childId");
        }
        // 👨‍👧 Parent cũng join để nhận trạng thái cập nhật thiết bị (pin, online)
        else if (role == "Parent" &&
            childId != null &&
            childId.isNotEmpty) {
          await joinDeviceGroup(childId);
          print("👨‍👧 [DeviceHub] Parent joined Device group-$childId (for status updates)");
        }
        else {
          print("⚠️ Không tìm thấy child_id hoặc role không hợp lệ (role=$role, childId=$childId)");
        }

      } catch (e) {
        print("⚠️ DeviceHub kết nối thất bại lần $attempt: $e");
        if (attempt < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (!connected) {
      print("❌ Không thể kết nối DeviceHub sau $maxRetries lần thử.");
      throw Exception("Kết nối DeviceHub thất bại sau nhiều lần thử.");
    }
  }

  // 👥 Tham gia group theo ChildId
  Future<void> joinDeviceGroup(String childId) async {
    if (_deviceConnection == null ||
        _deviceConnection!.state != HubConnectionState.Connected) {
      print("⚠️ DeviceHub chưa sẵn sàng, đang kết nối lại...");
      await connectDeviceHub();
    }

    try {
      await _deviceConnection!.invoke("JoinGroup", args: [childId]);
      print("👥 Đã join group thiết bị-$childId");
    } catch (e) {
      print("⚠️ Lỗi khi join Device group: $e");
    }
  }

  // 🔒 Nhận sự kiện khoá thiết bị (Child nhận)
  void onDeviceLocked(Function(Map<String, dynamic>) onLocked) {
    _deviceConnection?.on("DeviceLocked", (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      print("🔒 [DeviceHub] Nhận DeviceLocked: $raw");
      if (raw is Map) onLocked(Map<String, dynamic>.from(raw));
    });
  }

  // 🔓 Nhận sự kiện mở khoá thiết bị (Child nhận)
  void onDeviceUnlocked(Function(Map<String, dynamic>) onUnlocked) {
    _deviceConnection?.on("DeviceUnlocked", (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      print("🔓 [DeviceHub] Nhận DeviceUnlocked: $raw");
      if (raw is Map) onUnlocked(Map<String, dynamic>.from(raw));
    });
  }

  // 🔋 Nhận sự kiện cập nhật trạng thái pin/online (Parent nhận)
  void onDeviceStatusUpdated(Function(Map<String, dynamic>) onUpdate) {
    _deviceConnection?.on("DeviceStatusUpdated", (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      print("📡 [DeviceHub] Device Status Updated: $raw");
      if (raw is Map) onUpdate(Map<String, dynamic>.from(raw));
    });
  }

  // 🛰️ Nhận sự kiện thay đổi trạng thái theo dõi (Parent & Child nhận)
  void onDeviceTrackingChanged(Function(Map<String, dynamic>) onChanged) {
    _deviceConnection?.on("DeviceTrackingChanged", (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      print("🛰️ [DeviceHub] Nhận DeviceTrackingChanged: $raw");
      if (raw is Map) onChanged(Map<String, dynamic>.from(raw));
    });
  }

  // 🧹 Ngắt kết nối thủ công
  Future<void> disconnectDeviceHub() async {
    try {
      if (_deviceConnection != null &&
          _deviceConnection!.state == HubConnectionState.Connected) {
        await _deviceConnection!.stop();
        print("❎ Đã ngắt kết nối DeviceHub.");
      }
    } catch (e) {
      print("⚠️ Lỗi khi disconnect DeviceHub: $e");
    }
  }
}
