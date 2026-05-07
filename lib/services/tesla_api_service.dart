import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

/// 스마트폰과 테슬라 차량 간의 통신을 담당하는 서비스 클래스
/// (실제 Tesla Fleet API 또는 토큰 기반 Oauth 방식을 시뮬레이션 합니다.)
class TeslaApiService {
  // 실제 서비스라면 https://owner-api.teslamotors.com 이런 주소를 사용합니다.
  final String _baseUrl = 'https://api.example.tesla.com'; 
  
  /// 차량 정보(배터리, 위치 등)를 가져옵니다.
  /// (현재는 1.5초 후 가짜 JSON 데이터를 응답해주는 식으로 구현됨)
  Future<Map<String, dynamic>> fetchVehicleData() async {
    // 실제 통신 딜레이(지연 시간) 연출
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // 테슬라 서버가 진짜 보내줄 법한 JSON 구조
    String mockJsonResponse = '''
    {
      "id": 1234567890,
      "state": "online",
      "display_name": "My Model Y",
      "charge_state": {
        "battery_level": 78,
        "est_battery_range": 384.5,
        "charging_state": "Disconnected"
      },
      "vehicle_state": {
        "locked": true,
        "odometer": 10502.3,
        "is_user_present": false,
        "center_display_state": 0,
        "fd_window": 0,
        "fp_window": 0
      },
      "climate_state": {
        "inside_temp": 18.2,
        "outside_temp": 12.0,
        "is_climate_on": false
      }
    }
    ''';
    
    return jsonDecode(mockJsonResponse);
  }

  /// 차량 잠금 제어 명령 (앱 -> 차)
  Future<bool> toggleLock(bool lockState) async {
    await Future.delayed(const Duration(milliseconds: 800)); // 서버 왕복 시간
    print('Command sent: \${lockState ? "Lock" : "Unlock"}');
    return true; // 성공적으로 명령이 떨어졌다고 가정
  }

  /// 프렁크(Front Trunk) 제어 명령
  Future<bool> openFrunk() async {
    await Future.delayed(const Duration(milliseconds: 600));
    print('Command sent: Open Frunk');
    return true;
  }

  /// 공조기(히터/에어컨) 켜기 버튼 명령
  Future<bool> toggleClimate(bool climateState) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    print('Command sent: \${climateState ? "Turn On" : "Turn Off"} Climate');
    return true;
  }
}
