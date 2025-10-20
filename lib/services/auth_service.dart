import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config_url.dart';

class AuthService {
  // đường dẫn tới API login
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
      print("📤 Request body: ${jsonEncode({"account": account, "password": password})}");
      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        bool status = data['status'] ?? false;
        if (!status) {
          return {"success": false, "message": data['msg'] ?? "Đăng nhập thất bại"};
        }

        // ✅ Lấy token từ bên trong data["data"]
        final tokenData = data['data'];
        if (tokenData == null || tokenData['token'] == null) {
          return {"success": false, "message": "Không nhận được token từ server."};
        }

        String token = tokenData['token'];
        String refreshToken = tokenData['refreshToken'];

        // ✅ Decode token để lấy thông tin user
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        print("🧩 Decoded token: $decodedToken");

        // ✅ Trích xuất UserId đúng key ASP.NET Identity
        final userId =
            decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']
                ?? decodedToken['sub']
                ?? '';

        // ✅ Lưu token, refresh token và user_id vào SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('jwt_token', token);
        prefs.setString('refresh_token', refreshToken);
        if (userId.isNotEmpty) {
          prefs.setString('user_id', userId);
          print("✅ Saved user_id: $userId");
        } else {
          print("⚠️ Không tìm thấy userId trong token!");
        }

        return {
          "success": true,
          "token": token,
          "refreshToken": refreshToken,
          "decodedToken": decodedToken,
        };
      } else {
        return {
          "success": false,
          "message": "Failed to login: ${response.statusCode}"
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}
