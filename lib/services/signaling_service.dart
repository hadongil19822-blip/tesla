import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

/// Firebase Realtime Database를 통한 WebRTC 시그널링 서비스.
/// 아이폰 앱과 테슬라 브라우저 사이의 WebRTC 연결 정보를 중계합니다.
class SignalingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  DatabaseReference? _roomRef;
  String? _roomPin;
  
  void Function(String)? onLog;
  void Function(Map<String, dynamic>)? onAnswerReceived;
  void Function(Map<String, dynamic>)? onIceCandidateReceived;

  String? get roomPin => _roomPin;

  /// 4자리 PIN으로 방 생성
  Future<String> createRoom() async {
    // 랜덤 4자리 PIN 생성
    _roomPin = (1000 + Random().nextInt(9000)).toString();
    _roomRef = _db.ref('rooms/$_roomPin');
    
    // 이전 데이터 정리
    await _roomRef!.remove();
    
    // 방 생성 (타임스탬프 기록)
    await _roomRef!.set({
      'created': ServerValue.timestamp,
      'status': 'waiting',
    });

    _log('방 생성됨: PIN $_roomPin');
    
    // answer 감시
    _roomRef!.child('answer').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _log('Answer 수신됨');
        onAnswerReceived?.call(data);
      }
    });

    // Tesla에서 보내는 ICE candidate 감시
    _roomRef!.child('tesla_candidates').onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        onIceCandidateReceived?.call(data);
      }
    });

    return _roomPin!;
  }

  /// WebRTC offer를 Firebase에 저장
  Future<void> sendOffer(String sdp) async {
    if (_roomRef == null) return;
    await _roomRef!.child('offer').set({
      'type': 'offer',
      'sdp': sdp,
    });
    await _roomRef!.child('status').set('offering');
    _log('Offer 전송됨');
  }

  /// 아이폰의 ICE candidate를 Firebase에 추가
  Future<void> sendIceCandidate(Map<String, dynamic> candidate) async {
    if (_roomRef == null) return;
    await _roomRef!.child('phone_candidates').push().set(candidate);
  }

  void _log(String msg) {
    onLog?.call(msg);
  }

  /// 방 정리
  Future<void> closeRoom() async {
    if (_roomRef != null) {
      await _roomRef!.remove();
      _roomRef = null;
      _roomPin = null;
      _log('방 삭제됨');
    }
  }
}
