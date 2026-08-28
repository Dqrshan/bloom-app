import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/crypto_util.dart';

enum SyncState {
  disconnected,
  connecting,
  connected,
  waitingApproval,
  syncing,
  success,
  error,
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;

  final _stateController = StreamController<SyncState>.broadcast();
  final _partnerController = StreamController<String?>.broadcast();
  final _approvalController = StreamController<Map<String, dynamic>>.broadcast();
  final _dataReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _syncApprovedController = StreamController<void>.broadcast();

  Stream<SyncState> get stateStream => _stateController.stream;
  Stream<String?> get partnerStream => _partnerController.stream;
  Stream<Map<String, dynamic>> get approvalStream => _approvalController.stream;
  Stream<Map<String, dynamic>> get dataReceivedStream => _dataReceivedController.stream;
  Stream<void> get syncApprovedStream => _syncApprovedController.stream;

  SyncState _currentState = SyncState.disconnected;
  SyncState get currentState => _currentState;

  String? _deviceId;
  String? _partnerId;
  String? _pairingCode;
  String? _sharedSecret;
  String _serverUrl = 'wss://bloom.darshanb.workers.dev/ws';
  DateTime? _lastSyncedAt;
  String? _pendingRequestId;

  String get deviceId => _deviceId ?? 'unknown';
  String? get partnerId => _partnerId;
  String get pairingCode => _pairingCode ?? '------';
  String? get sharedSecret => _sharedSecret;
  String get serverUrl => _serverUrl;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get pendingRequestId => _pendingRequestId;
  bool get isPartnerLinked => _partnerId != null && _partnerId!.isNotEmpty;

  void _updateState(SyncState s) {
    _currentState = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('bloom_device_id');
    if (_deviceId == null) {
      _deviceId = CryptoUtil.generateDeviceId();
      await prefs.setString('bloom_device_id', _deviceId!);
    }

    _pairingCode = prefs.getString('bloom_pairing_code');
    if (_pairingCode == null) {
      _pairingCode = CryptoUtil.generatePairingCode();
      await prefs.setString('bloom_pairing_code', _pairingCode!);
    }

    _partnerId = prefs.getString('bloom_partner_id');
    _sharedSecret = prefs.getString('bloom_shared_secret');
    
    // Automatically migrate any legacy localhost setting to the Cloudflare relay
    final savedUrl = prefs.getString('bloom_server_url');
    if (savedUrl == null || savedUrl.isEmpty || savedUrl.contains('localhost')) {
      _serverUrl = 'wss://bloom.darshanb.workers.dev/ws';
      await prefs.setString('bloom_server_url', _serverUrl);
    } else {
      _serverUrl = savedUrl;
    }

    final lastSyncMillis = prefs.getInt('bloom_last_sync');
    if (lastSyncMillis != null) {
      _lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloom_server_url', _serverUrl);
    if (_currentState == SyncState.connected || _currentState == SyncState.connecting) {
      disconnect();
      await connect();
    }
  }

  Future<void> regeneratePairingCode() async {
    _pairingCode = CryptoUtil.generatePairingCode();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bloom_pairing_code', _pairingCode!);
    if (_currentState == SyncState.connected) {
      _send({
        'type': 'pair_request',
        'pairingCode': _pairingCode,
        'deviceId': _deviceId,
        'deviceName': 'Bloom User',
      });
    }
  }

  Future<void> connect([String? customUrl]) async {
    if (_deviceId == null) await init();
    final targetUrl = customUrl ?? _serverUrl;
    _updateState(SyncState.connecting);

    try {
      _heartbeatTimer?.cancel();
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(targetUrl));

      _channel!.stream.listen(
        _onMessage,
        onDone: () {
          _heartbeatTimer?.cancel();
          _updateState(SyncState.disconnected);
        },
        onError: (e) {
          _heartbeatTimer?.cancel();
          _updateState(SyncState.error);
        },
      );

      try {
        await _channel!.ready;
      } catch (_) {
        _heartbeatTimer?.cancel();
        _updateState(SyncState.error);
        return;
      }

      // Register device with relay server
      _send({'type': 'register', 'deviceId': _deviceId});
      _updateState(SyncState.connected);

      // Register my pairing code on relay
      if (_pairingCode != null) {
        _send({
          'type': 'pair_request',
          'pairingCode': _pairingCode,
          'deviceId': _deviceId,
          'deviceName': 'Bloom User',
        });
      }

      // Heartbeat ping every 20 seconds
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (_currentState == SyncState.connected) {
          _send({'type': 'ping'});
        }
      });
    } catch (_) {
      _updateState(SyncState.error);
    }
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateState(SyncState.disconnected);
  }

  Future<void> unlinkPartner() async {
    _partnerId = null;
    _sharedSecret = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bloom_partner_id');
    await prefs.remove('bloom_shared_secret');
    if (!_partnerController.isClosed) _partnerController.add(null);
  }

  void pairWith(String partnerCode) {
    if (_currentState != SyncState.connected) {
      connect();
    }
    final cleanCode = partnerCode.trim().toUpperCase();
    _send({
      'type': 'pair_request',
      'pairingCode': cleanCode,
      'deviceId': _deviceId,
      'deviceName': 'Bloom Partner',
    });
  }

  void requestSync() {
    if (_partnerId == null || _partnerId!.isEmpty) return;
    final reqId = CryptoUtil.generateDeviceId();
    _send({
      'type': 'sync_request',
      'fromDeviceId': _deviceId,
      'toDeviceId': _partnerId,
      'requestId': reqId,
      'dataTypes': ['cycles', 'notes'],
    });
    _updateState(SyncState.syncing);
  }

  void approveSync(String requestId) {
    _send({
      'type': 'sync_approved',
      'requestId': requestId,
      'deviceId': _deviceId,
    });
    _pendingRequestId = null;
    _updateState(SyncState.syncing);
    if (!_syncApprovedController.isClosed) {
      _syncApprovedController.add(null);
    }
  }

  void denySync(String requestId) {
    _send({
      'type': 'sync_denied',
      'requestId': requestId,
      'deviceId': _deviceId,
    });
    _pendingRequestId = null;
    _updateState(SyncState.connected);
  }

  void sendEncryptedSyncData(Map<String, dynamic> rawPayload) {
    if (_partnerId == null) return;
    final secret = _sharedSecret ?? 'bloom_default_secret_key_$pairingCode';
    final jsonStr = jsonEncode(rawPayload);
    final encResult = CryptoUtil.encryptPayload(jsonStr, secret);

    _send({
      'type': 'sync_data',
      'fromDeviceId': _deviceId,
      'toDeviceId': _partnerId,
      'payload': encResult['ciphertext'],
      'iv': encResult['iv'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _send({
      'type': 'sync_complete',
      'fromDeviceId': _deviceId,
      'toDeviceId': _partnerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _markSyncSuccess();
  }

  Future<void> _markSyncSuccess() async {
    _lastSyncedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bloom_last_sync', _lastSyncedAt!.millisecondsSinceEpoch);
    _updateState(SyncState.success);
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentState == SyncState.success) {
        _updateState(SyncState.connected);
      }
    });
  }

  void _onMessage(dynamic data) async {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;

      switch (type) {
        case 'registered':
          _updateState(SyncState.connected);
          break;

        case 'pair_request':
          // Another device wants to pair with us using our pairing code
          final fromDevice = msg['fromDeviceId'] as String?;
          if (fromDevice != null && fromDevice != _deviceId) {
            _partnerId = fromDevice;
            _sharedSecret = 'bloom_secret_${_pairingCode}_$fromDevice';
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bloom_partner_id', _partnerId!);
            await prefs.setString('bloom_shared_secret', _sharedSecret!);

            // Auto-accept pair request
            _send({
              'type': 'pair_accept',
              'fromDeviceId': fromDevice,
              'deviceId': _deviceId,
            });

            if (!_partnerController.isClosed) _partnerController.add(_partnerId);
          }
          break;

        case 'pair_accepted':
        case 'pair_request_sent':
          final pId = (msg['partnerDeviceId'] ?? msg['fromDeviceId']) as String?;
          if (pId != null) {
            _partnerId = pId;
            _sharedSecret = 'bloom_secret_${_pairingCode}_$pId';
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bloom_partner_id', _partnerId!);
            await prefs.setString('bloom_shared_secret', _sharedSecret!);
            if (!_partnerController.isClosed) _partnerController.add(_partnerId);
          }
          break;

        case 'sync_request':
          final reqId = msg['requestId'] as String? ?? '';
          _pendingRequestId = reqId;
          _updateState(SyncState.waitingApproval);
          if (!_approvalController.isClosed) {
            _approvalController.add(msg);
          }
          break;

        case 'sync_approved':
          _updateState(SyncState.syncing);
          if (!_syncApprovedController.isClosed) {
            _syncApprovedController.add(null);
          }
          break;

        case 'sync_denied':
          _updateState(SyncState.connected);
          break;

        case 'sync_data':
          final rawCipher = msg['payload'];
          final iv = msg['iv'] as String?;
          if (rawCipher != null) {
            Map<String, dynamic> decryptedPayload = {};
            final secret = _sharedSecret ?? 'bloom_default_secret_key_$pairingCode';

            if (iv != null && rawCipher is String) {
              try {
                final decryptedJson = CryptoUtil.decryptPayload(rawCipher, iv, secret);
                decryptedPayload = jsonDecode(decryptedJson) as Map<String, dynamic>;
              } catch (_) {
                // Fallback in case raw plaintext was passed
                try {
                  decryptedPayload = jsonDecode(rawCipher) as Map<String, dynamic>;
                } catch (_) {}
              }
            } else if (rawCipher is Map) {
              decryptedPayload = Map<String, dynamic>.from(rawCipher);
            }

            if (!_dataReceivedController.isClosed && decryptedPayload.isNotEmpty) {
              _dataReceivedController.add(decryptedPayload);
            }
          }
          break;

        case 'sync_complete':
          await _markSyncSuccess();
          break;

        case 'error':
          _updateState(SyncState.error);
          break;

        case 'pong':
          // Keep-alive acknowledgment
          break;
      }
    } catch (_) {}
  }

  void _send(Map<String, dynamic> msg) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (_) {}
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _partnerController.close();
    _approvalController.close();
    _dataReceivedController.close();
  }
}
