import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 스마트폰과 테슬라 차량 간의 통신을 담당하는 서비스 클래스
/// (실제 Tesla Owner API 연동)
class TeslaApiService {
  String _buildUrl(String path) {
    final targetUrl = 'https://owner-api.teslamotors.com/api/1\$path';
    if (kIsWeb) {
      // 웹 환경에서 CORS 차단을 피하기 위해 공개 프록시를 경유합니다.
      return 'https://corsproxy.io/?\${Uri.encodeComponent(targetUrl)}';
    }
    return targetUrl;
  }

  String? _accessToken;
  String? _vehicleId;

  Future<void> _initToken() async {
    if (_accessToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('tesla_token');
    }
  }

  void setToken(String token) {
    _accessToken = token;
  }

  Future<Map<String, String>> _getHeaders() async {
    await _initToken();
    return {
      'Authorization': 'Bearer \$_accessToken',
      'Content-Type': 'application/json',
      'User-Agent': 'TeslaSuperApp/1.0'
    };
  }

  /// 1. 토큰 유효성 검증 (차량 목록 조회)
  Future<bool> verifyToken(String token) async {
    setToken(token);
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(_buildUrl('/vehicles')), headers: headers);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final vehicles = data['response'] as List;
        if (vehicles.isNotEmpty) {
          _vehicleId = vehicles[0]['id_s'];
          return true; // 성공적으로 차량을 찾음
        }
      } else {
        debugPrint('Token Error: \${response.statusCode} - \${response.body}');
      }
    } catch (e) {
      debugPrint('Verify Exception: \$e');
    }
    return false;
  }

  /// 차량 ID 가져오기
  Future<String?> getVehicleId() async {
    if (_vehicleId != null) return _vehicleId;
    
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse(_buildUrl('/vehicles')), headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final vehicles = data['response'] as List;
        if (vehicles.isNotEmpty) {
          _vehicleId = vehicles[0]['id_s'];
          return _vehicleId;
        }
      }
    } catch (e) {
      debugPrint('Vehicle ID Fetch Error: \$e');
    }
    return null;
  }

  /// 2. 실제 차량 정보 조회
  Future<Map<String, dynamic>> fetchVehicleData() async {
    final vid = await getVehicleId();
    if (vid == null) {
      throw Exception('차량을 찾을 수 없거나 토큰이 유효하지 않습니다.');
    }

    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(_buildUrl('/vehicles/\$vid/vehicle_data')), headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else if (response.statusCode == 408) {
      // 차량이 수면 상태임 -> 깨우기 요청 보냄
      await wakeUp();
      throw Exception('차량이 절전 모드입니다. 깨우는 중이므로 10~20초 뒤 새로고침 하세요.');
    } else {
      throw Exception('데이터 로드 실패: \${response.statusCode}');
    }
  }

  /// 차량 깨우기 (Wake Up)
  Future<bool> wakeUp() async {
    final vid = await getVehicleId();
    if (vid == null) return false;
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse(_buildUrl('/vehicles/\$vid/wake_up')), headers: headers);
    return response.statusCode == 200;
  }

  /// 공통 커맨드 전송 함수
  Future<bool> _sendCommand(String command, [Map<String, dynamic>? body]) async {
    final vid = await getVehicleId();
    if (vid == null) return false;

    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse(_buildUrl('/vehicles/\$vid/command/\$command')),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response']['result'] == true;
    }
    
    debugPrint('Command failed: \${response.statusCode} - \${response.body}');
    return false;
  }

  /// 3. 제어 명령: 도어 잠금/해제
  Future<bool> toggleLock(bool lockState) async {
    return _sendCommand(lockState ? 'door_lock' : 'door_unlock');
  }

  /// 제어 명령: 프렁크 열기
  Future<bool> openFrunk() async {
    return _sendCommand('actuate_trunk', {'which_trunk': 'front'});
  }

  /// 제어 명령: 공조(에어컨) 제어
  Future<bool> toggleClimate(bool climateState) async {
    return _sendCommand(climateState ? 'auto_conditioning_start' : 'auto_conditioning_stop');
  }
  
  /// 제어 명령: 경적 울리기
  Future<bool> honkHorn() async {
    return _sendCommand('honk_horn');
  }
}
