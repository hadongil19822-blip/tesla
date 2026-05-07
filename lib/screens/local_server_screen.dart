import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class LocalServerScreen extends StatefulWidget {
  const LocalServerScreen({super.key});

  @override
  State<LocalServerScreen> createState() => _LocalServerScreenState();
}

class _LocalServerScreenState extends State<LocalServerScreen> {
  HttpServer? _server;
  String _ipAddress = '확인 중...';
  int _port = 8080;
  bool _isRunning = false;

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    try {
      final info = NetworkInfo();
      String? wifiIP = await info.getWifiIP();
      
      if (wifiIP == null || wifiIP.isEmpty) {
        setState(() => _ipAddress = 'Wi-Fi 핫스팟을 켜주세요');
        return;
      }

      setState(() => _ipAddress = wifiIP);

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      setState(() => _isRunning = true);

      _server!.listen((HttpRequest request) {
        if (request.uri.path == '/') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(_getDashboardHtml(wifiIP, _port))
            ..close();
        } else if (request.uri.path == '/ws') {
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            _handleWebSocket(ws);
          });
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not found')
            ..close();
        }
      });
    } catch (e) {
      setState(() => _ipAddress = '서버 시작 실패: $e');
    }
  }

  void _handleWebSocket(WebSocket ws) async {
    // 1. 화면 캡처 시작
    try {
      _localStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {'deviceId': 'broadcast'},
        'audio': false,
      });
    } catch (e) {
      print('화면 캡처 오류: $e');
      return;
    }

    // 2. WebRTC 연결 설정
    _peerConnection = await createPeerConnection({
      'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}],
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      ws.add(jsonEncode({
        'type': 'candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      }));
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // 3. Offer 생성 및 전송
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    ws.add(jsonEncode({
      'type': 'offer',
      'sdp': offer.sdp,
    }));

    // 4. 클라이언트(테슬라)로부터 Answer 및 ICE 처리
    ws.listen((message) async {
      final data = jsonDecode(message);
      if (data['type'] == 'answer') {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(data['sdp'], data['type']),
        );
      } else if (data['type'] == 'candidate') {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']),
        );
      }
    });
  }

  String _getDashboardHtml(String ip, int port) {
    return '''
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>Tesla Mirroring</title>
  <style>
    body { background: #000; color: #fff; margin: 0; padding: 0; overflow: hidden; display: flex; flex-direction: column; height: 100vh; }
    #video { width: 100%; height: 100%; object-fit: contain; }
    .status { display: none; }
  </style>
</head>
<body>
  <div class="status" id="status">연결 대기 중...</div>
  <video id="video" autoplay playsinline muted></video>

  <script>
    const video = document.getElementById('video');
    video.addEventListener('resize', () => {
      if (video.videoWidth > video.videoHeight) {
        video.style.objectFit = 'cover'; // 가로 모드일 때는 꽉 채움 (위아래 블랙바 제거)
      } else {
        video.style.objectFit = 'contain'; // 세로 모드일 때는 원본 비율 유지 (잘림 방지)
      }
    });

    const ws = new WebSocket('ws://$ip:$port/ws');
    const pc = new RTCPeerConnection({
      iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    });

    ws.onmessage = async (e) => {
      const msg = JSON.parse(e.data);
      if (msg.type === 'offer') {
        document.getElementById('status').innerText = '연결 중...';
        await pc.setRemoteDescription(new RTCSessionDescription(msg));
        const answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        ws.send(JSON.stringify({ type: 'answer', sdp: answer.sdp }));
      } else if (msg.type === 'candidate') {
        await pc.addIceCandidate(new RTCIceCandidate(msg));
      }
    };

    pc.onicecandidate = (e) => {
      if (e.candidate) {
        ws.send(JSON.stringify({
          type: 'candidate',
          candidate: e.candidate.candidate,
          sdpMid: e.candidate.sdpMid,
          sdpMLineIndex: e.candidate.sdpMLineIndex
        }));
      }
    };

    pc.ontrack = (e) => {
      document.getElementById('status').innerText = '미러링 중';
      document.getElementById('video').srcObject = e.streams[0];
    };

    ws.onclose = () => {
      document.getElementById('status').innerText = '연결 끊김';
    };
  </script>
</body>
</html>
    ''';
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _peerConnection?.dispose();
    _server?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text('로컬 미러링 서버'),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isRunning ? Icons.connected_tv : Icons.tv_off,
              size: 80,
              color: _isRunning ? Colors.blueAccent : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              _isRunning ? '테슬라와 연결할 준비가 되었습니다' : '서버가 중지되었습니다',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 40),
            const Text('테슬라 브라우저에서 아래 주소를 입력하세요:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                'http://$_ipAddress:$_port',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                '차량 탑승 후 스마트폰의 핫스팟을 켜고, 테슬라를 핫스팟에 연결하세요.\\n접속하면 폰 화면 녹화(방송) 권한을 요청합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
            )
          ],
        ),
      ),
    );
  }
}
