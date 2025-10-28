import 'dart:convert';

import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/zone/safe_zone_response_model.dart';
import 'package:frontend_qlte/models/zone/create_safe_zone_request_model.dart';
import 'package:frontend_qlte/models/zone/update_safe_zone_request_model.dart';
import 'package:http/http.dart' as http;

class SafeZoneService {
  static final String _baseUrl = '${Config_URL.baseUrl}SafeZone';

  static Future<SafeZoneResponse> getSafeZoneByUserIdAndChildId(
    String userId,
    String childId,
    String token,
  ) async {
    try {
      var uri = Uri.parse(
        '$_baseUrl/GetSafeZoneByUserIdAndChildId?userId=$userId&childId=$childId',
      );
      var response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // thêm token vào header
        },
      );
      final jsonData = jsonDecode(response.body);
      final value = SafeZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return SafeZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return SafeZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// Tạo vùng an toàn
  static Future<SafeZoneResponse> createSafeZone(
    CreateSafeZoneRequest request,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/CreateSafeZone'); // endpoint POST
      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()), // gửi body dạng JSON
      );

      final jsonData = jsonDecode(response.body);
      final value = SafeZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return SafeZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return SafeZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// update vùng an toàn
  static Future<SafeZoneResponse> updateSafeZone(
    UpdateSafeZoneRequest request,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/UpdateSafeZone'); // endpoint POST
      var response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()), // gửi body dạng JSON
      );
      final jsonData = jsonDecode(response.body);
      final value = SafeZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return SafeZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return SafeZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// Xóa vùng an toàn
  static Future<SafeZoneResponse> deleteSafeZone(
    String safeZoneId,
    String token,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/DeleteSafeZone?safeZoneId=$safeZoneId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SafeZoneResponse.fromJson(jsonData);
      } else {
        return SafeZoneResponse(
          status: false,
          msg: jsonData['msg'] ?? 'Xóa vùng an toàn thất bại',
          data: [],
        );
      }
    } catch (e) {
      return SafeZoneResponse(
        status: false,
        msg: 'Không thể kết nối server: $e',
        data: [],
      );
    }
  }
}
