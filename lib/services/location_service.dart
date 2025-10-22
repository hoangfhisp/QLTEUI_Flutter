import 'dart:convert';

import 'package:frontend_qlte/config/config_url.dart';
import 'package:frontend_qlte/models/location_history_response_model.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final String _baseUrl = '${Config_URL.baseUrl}Location';

  static Future<LocationHistoryResponseModel> getLocationHistoryNewByChildId(
    String childId,
    String token,
  ) async {
    try {
      var uri = Uri.parse('$_baseUrl/GetLocationHistoryNew?childId=$childId');
      var response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // thêm token vào header
        },
      );
      final jsonData = jsonDecode(response.body);
      final value = LocationHistoryResponseModel.fromJson(jsonData);
      if (response.statusCode == 200) {
        return value;
      } else {
        return LocationHistoryResponseModel(
          status: false,
          msg: 'Lỗi: ${value.msg}',
          data: [],
        );
      }
    } catch (e) {
      return LocationHistoryResponseModel(
        status: false,
        msg: 'Không thể kết nối server.',
        data: [],
      );
    }
  }

  

}
