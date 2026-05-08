import 'dart:io';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:http/http.dart' as http;

/// Pinggy.io SSH 터널을 통해 로컬 서버를 공개 HTTPS URL로 노출하는 서비스.
/// 맥북 없이 아이폰 앱에서 직접 터널을 생성합니다.
class TunnelService {
  SSHClient? _client;
  String? _publicUrl;
  String? _shortUrl;
  bool _isConnected = false;
  void Function(String)? onLog;
  void Function(String)? onUrlReady;
  void Function()? onDisconnected;

  String? get publicUrl => _publicUrl;
  String? get shortUrl => _shortUrl;
  bool get isConnected => _isConnected;

  // 앱 내장 SSH 키 (pinggy는 아무 키나 수락 - 익명 터널링)
  static const _embeddedPrivateKey = '''-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACB4dVy1+v1pPbVJqbmxGEX4Am+K8UV4gOL+eAVqRokYfwAAALDX/hpV1/4a
VQAAAAtzc2gtZWQyNTUxOQAAACB4dVy1+v1pPbVJqbmxGEX4Am+K8UV4gOL+eAVqRokYfw
AAAEDqJxWuP5btcxM4ROIjjY88Jdy0ZV+b+nvYX+QoPgKGZHh1XLX6/Wk9tUmpubEYRfgC
b4rxRXiA4v54BWpGiRh/AAAAJmhhZG9uZ2lsQGhhZG9uZy1pbC11aS1NYWNCb29rQWlyLm
xvY2FsAQIDBAUGBw==
-----END OPENSSH PRIVATE KEY-----''';

  /// 로컬 서버를 공개 HTTPS URL로 노출합니다.
  Future<String?> startTunnel(String localIp, int localPort) async {
    try {
      _log('터널 연결 시작...');

      // SSH 키 파싱
      List<SSHKeyPair> keyPairs;
      try {
        keyPairs = SSHKeyPair.fromPem(_embeddedPrivateKey);
        _log('SSH 키 로드 완료 (${keyPairs.length}개)');
      } catch (e) {
        _log('SSH 키 파싱 실패: $e');
        return null;
      }

      // pinggy에 SSH 연결 (포트 443)
      _log('pinggy.io 연결 중...');
      final socket = await SSHSocket.connect('a.pinggy.io', 443);
      _log('소켓 연결 성공');

      _client = SSHClient(
        socket,
        username: 'nokey',
        identities: keyPairs,  // SSH 키로 인증
        onVerifyHostKey: (algorithm, hostKey) async => true,
        onUserauthBanner: (banner) {
          _log('배너 수신됨');
          _extractUrl(banner);
        },
        printDebug: (msg) {
          final m = msg ?? '';
          // URL이 포함되어 있으면 추출 시도
          if (m.contains('pinggy') || m.contains('.link') || m.contains('https://')) {
            _log('SSH 메시지: $m');
            _extractUrl(m);
          }
          // 중요 메시지 로그
          if (m.contains('error') || m.contains('fail') || 
              m.contains('Success') || m.contains('authenticated')) {
            _log('SSH: $m');
          }
        },
      );

      _log('인증 대기 중...');
      await _client!.authenticated;
      _log('인증 성공! 포트 포워딩 요청 중...');

      // 원격 포트 포워딩 요청
      final forward = await _client!.forwardRemote(port: 0);

      if (forward == null) {
        _log('포트 포워딩 실패');
        // shell 출력에서 URL 획득 시도
        await _tryGetUrlViaShell();
        if (_publicUrl == null) {
          return null;
        }
      } else {
        _isConnected = true;
        _log('포트 포워딩 성공!');

        // 들어오는 연결을 로컬 서버로 프록시
        _handleForwardConnections(forward, localIp, localPort);
      }

      // URL을 아직 못 받았으면 shell에서 시도
      if (_publicUrl == null) {
        await _tryGetUrlViaShell();
      }

      // 연결 모니터링
      _client!.done.then((_) {
        _log('SSH 연결 종료됨');
        _isConnected = false;
        onDisconnected?.call();
      });

      return _publicUrl;
    } catch (e) {
      _log('터널 시작 실패: $e');
      _isConnected = false;
      return null;
    }
  }

  Future<void> _tryGetUrlViaShell() async {
    try {
      _log('Shell 열어서 URL 대기 중...');
      final shell = await _client!.shell(pty: null);
      final allOutput = StringBuffer();

      // Shell stdout을 실시간으로 읽으면서 URL이 나올 때까지 대기
      bool found = false;
      shell.stdout.listen((data) {
        final text = utf8.decode(data);
        allOutput.write(text);
        _log('수신: ${text.trim()}');
        
        if (!found) {
          _extractUrl(allOutput.toString());
          if (_publicUrl != null) {
            found = true;
          }
        }
      });

      // 최대 15초 대기
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_publicUrl != null) {
          _log('URL 획득 완료!');
          return;
        }
      }

      if (_publicUrl == null) {
        _log('15초 내 URL 미수신. 전체 출력: ${allOutput.toString()}');
      }
    } catch (e) {
      _log('Shell URL 획득 실패: $e');
    }
  }

  void _extractUrl(String text) {
    // Pinggy URL 패턴: https://xxxx-x-x-x-x.run.pinggy-free.link
    final urlRegex = RegExp(r'https://[a-zA-Z0-9\-]+\.(?:run\.)?pinggy[a-zA-Z0-9\-]*\.link');
    final matches = urlRegex.allMatches(text);

    for (final match in matches) {
      final url = match.group(0);
      if (url != null && _publicUrl == null) {
        _publicUrl = url;
        _log('✅ 공개 URL: $_publicUrl');
        _isConnected = true;
        // 단축 URL 자동 생성
        _shortenUrl(url);
        onUrlReady?.call(_publicUrl!);
        break;
      }
    }

    // 첫 번째 패턴이 안 맞으면 더 넓은 패턴으로 시도
    if (_publicUrl == null) {
      final broadRegex = RegExp(r'https://[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+\.link');
      final broadMatches = broadRegex.allMatches(text);
      for (final match in broadMatches) {
        final url = match.group(0);
        if (url != null && _publicUrl == null && url.contains('pinggy')) {
          _publicUrl = url;
          _log('✅ 공개 URL: $_publicUrl');
          _isConnected = true;
          onUrlReady?.call(_publicUrl!);
          break;
        }
      }
    }
  }

  void _handleForwardConnections(SSHRemoteForward forward, String localIp, int localPort) {
    forward.connections.listen((connection) async {
      try {
        _log('터널 요청 → $localIp:$localPort');
        final socket = await Socket.connect(localIp, localPort);

        connection.stream.cast<List<int>>().listen(
          socket.add,
          onDone: () => socket.close(),
          onError: (e) => socket.close(),
        );
        socket.listen(
          connection.sink.add,
          onDone: () => connection.sink.close(),
          onError: (e) => connection.sink.close(),
        );
      } catch (e) {
        _log('프록시 실패: $e');
      }
    });
  }

  /// is.gd 무료 API로 단축 URL 생성
  Future<void> _shortenUrl(String longUrl) async {
    try {
      final response = await http.get(
        Uri.parse('https://is.gd/create.php?format=simple&url=${Uri.encodeComponent(longUrl)}'),
      );
      if (response.statusCode == 200 && response.body.startsWith('https://')) {
        _shortUrl = response.body.trim();
        _log('📎 단축 URL: $_shortUrl');
      }
    } catch (e) {
      _log('단축 URL 생성 실패 (무시): $e');
    }
  }

  void _log(String msg) {
    print('[Tunnel] $msg');
    onLog?.call(msg);
  }

  Future<void> stopTunnel() async {
    _client?.close();
    _client = null;
    _publicUrl = null;
    _shortUrl = null;
    _isConnected = false;
    onDisconnected?.call();
    _log('터널 종료됨');
  }
}
