import 'dart:convert';

import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/zone/danger_zone_response_model.dart';
import 'package:frontend_qlte/models/zone/create_danger_zone_request_model.dart';
import 'package:frontend_qlte/models/zone/update_danger_zone_request_model.dart';
import 'package:http/http.dart' as http;

class DangerZoneService{
  static final String _baseUrl = '${Config_URL.baseUrl}DangerZone';

  static Future<DangerZoneResponse> getDangerZoneByUserIdAndChildId(
    String userId,
    String childId,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/GetDangerZoneByUserIdAndChildId?userId=$userId&childId=$childId');
      var response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // thêm token vào header
        },
      );
      final jsonData = jsonDecode(response.body);
      final value = DangerZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return DangerZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return DangerZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// Tạo vùng nguy hiểm
  static Future<DangerZoneResponse> createDangerZone(
    CreateDangerZoneRequest request,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/CreateDangerZone'); // endpoint POST
      var response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()), // gửi body dạng JSON
      );

      final jsonData = jsonDecode(response.body);
      final value = DangerZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return DangerZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return DangerZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// update vùng nguy hiểm
  static Future<DangerZoneResponse> updateDangerZone(
    UpdateDangerZoneRequest request,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/UpdateDangerZone'); // endpoint POST
      var response = await http.put(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()), // gửi body dạng JSON
      );

      final jsonData = jsonDecode(response.body);
      final value = DangerZoneResponse.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return DangerZoneResponse(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return DangerZoneResponse(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  /// Xóa vùng nguy hiểm
  static Future<DangerZoneResponse> deleteDangerZone(
    String dangerZoneId,
    String token,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/DeleteDangerZone?dangerZoneId=$dangerZoneId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return DangerZoneResponse.fromJson(jsonData);
      } else {
        return DangerZoneResponse(
          status: false,
          msg: jsonData['msg'] ?? 'Xóa vùng an toàn thất bại',
          data: [],
        );
      }
    } catch (e) {
      return DangerZoneResponse(
        status: false,
        msg: 'Không thể kết nối server: $e',
        data: [],
      );
    }
  }
}