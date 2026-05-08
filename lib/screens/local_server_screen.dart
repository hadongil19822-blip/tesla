import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signaling_service.dart';

class LocalServerScreen extends StatefulWidget {
  const LocalServerScreen({super.key});

  @override
  State<LocalServerScreen> createState() => _LocalServerScreenState();
}

class _LocalServerScreenState extends State<LocalServerScreen> {
  final SignalingService _signaling = SignalingService();
  String? _pin;
  String _status = '준비 중...';
  bool _isConnected = false;
  final List<String> _logs = [];

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _initSignaling();
  }

  void _log(String msg) {
    print('[Mirror] $msg');
    if (mounted) {
      setState(() {
        _logs.add('[${DateTime.now().toString().substring(11, 19)}] $msg');
        if (_logs.length > 30) _logs.removeAt(0);
      });
    }
  }

  Future<void> _initSignaling() async {
    setState(() => _status = '방 생성 중...');

    _signaling.onLog = (msg) => _log(msg);

    _signaling.onAnswerReceived = (data) async {
      _log('테슬라에서 응답 수신!');
      if (_peerConnection != null) {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
        setState(() {
          _status = '미러링 중!';
          _isConnected = true;
        });
      }
    };

    _signaling.onIceCandidateReceived = (data) async {
      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    };

    try {
      final pin = await _signaling.createRoom();
      setState(() {
        _pin = pin;
        _status = '테슬라에서 접속 대기 중';
      });

      // WebRTC 준비 및 Offer 전송
      await _setupWebRTC();
    } catch (e) {
      _log('초기화 실패: $e');
      setState(() => _status = '오류: $e');
    }
  }

  Future<void> _setupWebRTC() async {
    try {
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {'deviceId': 'broadcast'},
        'audio': false,
      });
      _log('화면 캡처 시작됨');
    } catch (e) {
      _log('화면 캡처 오류: $e');
      return;
    }

    _peerConnection = await createPeerConnection(_iceServers);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _signaling.sendIceCandidate({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onConnectionState = (state) {
      _log('연결 상태: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          _isConnected = true;
          _status = '🎉 미러링 중!';
        });
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        setState(() {
          _isConnected = false;
          _status = '연결 끊김';
        });
      }
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _signaling.sendOffer(offer.sdp!);
    _log('Offer 전송 완료, 테슬라 접속 대기...');
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('복사됨!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _restart() async {
    _localStream?.dispose();
    _peerConnection?.dispose();
    await _signaling.closeRoom();
    setState(() {
      _pin = null;
      _isConnected = false;
      _logs.clear();
    });
    _initSignaling();
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.dispose();
    _signaling.closeRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const webUrl = 'hadongil.github.io/tesla';

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('테슬라 미러링'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _restart),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 상태 아이콘
                Icon(
                  _isConnected ? Icons.cast_connected :
                  _pin != null ? Icons.cast : Icons.hourglass_top,
                  size: 56,
                  color: _isConnected ? Colors.greenAccent :
                         _pin != null ? Colors.cyanAccent : Colors.orangeAccent,
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.greenAccent : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (_pin != null) ...[
                  const SizedBox(height: 30),

                  // STEP 1: 테슬라에서 접속할 주소
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.cyanAccent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              '테슬라 브라우저에서 접속:',
                              style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _copyToClipboard(webUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.cyanAccent),
                            ),
                            child: const Text(
                              webUrl,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('항상 같은 주소! 즐겨찾기 등록하세요', 
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // STEP 2: PIN 입력
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pin, color: Colors.greenAccent, size: 18),
                            SizedBox(width: 6),
                            Text(
                              '접속 후 아래 PIN 입력:',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _pin!,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                            letterSpacing: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // 로그
                Container(
                  width: double.infinity,
                  height: 120,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    reverse: true,
                    itemBuilder: (_, i) => Text(
                      _logs[_logs.length - 1 - i],
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Courier'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
