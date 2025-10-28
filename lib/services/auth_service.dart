import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';
import '../utils/jwt_helper.dart';
import '../utils/http_response_helper.dart';
import 'package:frontend_qlte/services/child_service.dart';

class AuthService {
  String get apiUrl => "${Config_URL.baseUrl}Auth/LoginUserToken";

  Future<Map<String, dynamic>> login(String account, String password) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "account": account,
          "password": password,
        }),
      );

      print("🔗 API Login URL = $apiUrl");
      print("📥 Status: ${response.statusCode}");
      print("📥 Body: ${response.body}");

      // ✅ Gọi helper để xử lý response tự động
      final result = HttpResponseHelper.handleStatus(response);

      // 🟢 Nếu là phản hồi thành công
      if (response.statusCode == 200 && result["success"] == true) {
        return await _handleSuccessResponse(response);
      }

      return result;
    } catch (e) {
      return {"success": false, "message": "Lỗi mạng hoặc server không phản hồi: $e"};
    }
  }

  /// ✅ Xử lý khi đăng nhập thành công
  Future<Map<String, dynamic>> _handleSuccessResponse(http.Response response) async {
    try {
      final data = jsonDecode(response.body);
      final tokenData = data['data'];
      if (tokenData == null || tokenData['token'] == null) {
        return {"success": false, "message": "Không nhận được token từ server."};
      }

      final token = tokenData['token'];
      final refreshToken = tokenData['refreshToken'];

      // 🧠 Giải mã thông tin từ token
      final role = JwtHelper.getRole(token);
      final userId = JwtHelper.getUserId(token) ?? '';
      final email = JwtHelper.getEmail(token) ?? 'Không rõ';

      print("🧩 Role: $role | UserId: $userId | Email: $email");

      // 💾 Lưu token & user info
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('refresh_token', refreshToken);
      if (userId.isNotEmpty) await prefs.setString('user_id', userId);
      await prefs.setString('role', role);

      // 🧒 Nếu là tài khoản trẻ em => gọi thêm API để lấy child_id
      if (role == "Children") {
        final childId = await _fetchChildIdByUserId(userId, token);
        if (childId != null && childId.isNotEmpty) {
          await prefs.setString('child_id', childId);
          print("🧒 Saved child_id (from API): $childId");

          // 🔍 Gọi tiếp API DeviceInfo/GetByChild để lấy deviceId
          final deviceUrl = Uri.parse("${Config_URL.baseUrl}DeviceInfo/GetByChild?childId=$childId");
          final deviceResponse = await http.get(deviceUrl, headers: {
            "Authorization": "Bearer $token",
          });

          print("🌐 Fetching DeviceInfo from: $deviceUrl");
          print("📥 Response status: ${deviceResponse.statusCode}");

          if (deviceResponse.statusCode == 200) {
            final json = jsonDecode(deviceResponse.body);
            if (json["status"] == true && json["data"]?["deviceId"] != null) {
              final deviceId = json["data"]["deviceId"].toString();
              await prefs.setString('device_id', deviceId);
              print("💾 Saved device_id=$deviceId for child=$childId");
            } else {
              print("⚠️ Không tìm thấy deviceId trong phản hồi DeviceInfo/GetByChild.");
            }
          } else {
            print("⚠️ Lỗi khi gọi DeviceInfo/GetByChild: ${deviceResponse.statusCode}");
          }
        } else {
          print("⚠️ Không thể lấy child_id cho userId: $userId");
        }
      }

      // 👨‍👧 Nếu là Parent => tự động lấy danh sách Children
      else if (role == "Parent") {
        try {
          print("👨‍👧 Bắt đầu tải danh sách con cho Parent userId=$userId ...");
          final childrenResponse = await ChildService.getChildrenByUserId(userId, token);

          if (childrenResponse.status && childrenResponse.data.isNotEmpty) {
            final firstChild = childrenResponse.data.first;
            await prefs.setString('child_id', firstChild.childId);
            print("✅ Saved first child_id for Parent: ${firstChild.childId}");
          } else {
            print("⚠️ Parent không có con nào trong hệ thống.");
          }
        } catch (e) {
          print("❌ Lỗi khi tải danh sách con cho Parent: $e");
        }
      }

      return {
        "success": true,
        "message": "Đăng nhập thành công!",
        "token": token,
        "refreshToken": refreshToken,
        "decodedToken": JwtHelper.decodeToken(token),
      };
    } catch (e) {
      return {"success": false, "message": "Lỗi khi xử lý phản hồi đăng nhập: $e"};
    }
  }

  /// 🔍 Gọi API lấy ChildId theo UserId
  Future<String?> _fetchChildIdByUserId(String userId, String token) async {
    final url = Uri.parse("${Config_URL.baseUrl}Child/GetChildByUserId?userId=$userId");

    try {
      final response = await http.get(url, headers: {
        "Authorization": "Bearer $token",
      });

      print("🌐 Fetching ChildId from: $url");
      print("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true && json["data"]?["childId"] != null) {
          return json["data"]["childId"].toString();
        }
      }
      return null;
    } catch (e) {
      print("❌ Lỗi khi gọi API lấy childId: $e");
      return null;
    }
  }
}
