import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/connection_state.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSub;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _lastError;
  String? _serverMessage;

  final Map<String, Completer<ActionResponse>> _pendingRequests = {};
  final _uuid = const Uuid();

  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.authenticated;
  String? get lastError => _lastError;
  String? get serverMessage => _serverMessage;

  void _setStatus(ConnectionStatus status, [String? error]) {
    _status = status;
    _lastError = error;
    notifyListeners();
  }

  Future<void> connect({
    required String host,
    required int port,
    required String token,
  }) async {
    // If already connected or connecting, cleanly reset first
    disconnect();

    _setStatus(ConnectionStatus.connecting);
    _pendingRequests.clear();

    log('[DevPad.WS] Attempting connection to ws://$host:$port');

    try {
      final wsUri = Uri.parse('ws://$host:$port');

      // 1. Explicit socket connect with timeout so we catch SocketExceptions, DNS, and timeouts
      final socket = await WebSocket.connect(
        wsUri.toString(),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection to $host:$port timed out after 5s. Check IP, port, and Windows Firewall.');
        },
      );

      _channel = IOWebSocketChannel(socket);

      // 2. Setup subscription with detailed error logging
      _streamSub = _channel!.stream.listen(
        (data) => _handleIncoming(data),
        onError: (err) {
          log('[DevPad.WS] WebSocket stream error: $err');
          _setStatus(ConnectionStatus.error, _formatError(err));
        },
        onDone: () {
          log('[DevPad.WS] WebSocket stream closed.');
          _setStatus(ConnectionStatus.disconnected);
        },
      );

      _setStatus(ConnectionStatus.connected);

      // 3. Authenticate with desktop companion
      log('[DevPad.WS] Connected to socket. Initiating authentication handshake...');
      final authResponse = await sendAction('auth', {'token': token});

      if (authResponse.isOk) {
        log('[DevPad.WS] Handshake successful. Device authenticated.');
        _setStatus(ConnectionStatus.authenticated);
      } else {
        final errText = authResponse.error ?? 'Authentication failed: Invalid pairing token.';
        log('[DevPad.WS] Authentication failed: $errText');
        _setStatus(ConnectionStatus.error, errText);
      }
    } on SocketException catch (e) {
      final errorMsg = _formatSocketException(e, host, port);
      log('[DevPad.WS] SocketException: $errorMsg');
      _setStatus(ConnectionStatus.error, errorMsg);
    } on TimeoutException catch (e) {
      log('[DevPad.WS] TimeoutException: ${e.message}');
      _setStatus(ConnectionStatus.error, e.message ?? 'Connection timed out.');
    } on WebSocketException catch (e) {
      log('[DevPad.WS] WebSocketException: ${e.message}');
      _setStatus(ConnectionStatus.error, 'WebSocket error: ${e.message}');
    } catch (e) {
      log('[DevPad.WS] Unexpected error during connection: $e');
      _setStatus(ConnectionStatus.error, 'Connection failed: $e');
    }
  }

  String _formatSocketException(SocketException e, String host, int port) {
    final osError = e.osError;
    final code = osError?.errorCode;
    if (code == 111 || code == 10061) {
      return 'Connection refused on $host:$port. Ensure server.py is running.';
    } else if (code == 110 || code == 10060) {
      return 'Connection timed out on $host:$port. Check Windows Firewall rule for port $port.';
    } else if (code == 113 || code == 10065) {
      return 'Host $host unreachable. Ensure phone and PC are on the same Wi-Fi.';
    }
    return 'Cannot reach $host:$port (${osError?.message ?? e.message})';
  }

  String _formatError(dynamic err) {
    if (err is SocketException) {
      return err.osError?.message ?? err.message;
    }
    return err.toString();
  }

  void disconnect() {
    try {
      _streamSub?.cancel();
    } catch (_) {}
    _streamSub = null;

    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(const ActionResponse(
          status: 'error',
          error: 'Connection closed',
        ));
      }
    }
    _pendingRequests.clear();
    _setStatus(ConnectionStatus.disconnected);
  }

  void _handleIncoming(dynamic data) {
    try {
      final decoded = json.decode(data as String) as Map<String, dynamic>;
      final response = ActionResponse.fromMap(decoded);

      log('[DevPad.WS] Received response: id=${response.id}, status=${response.status}');

      if (response.id != null && _pendingRequests.containsKey(response.id)) {
        _pendingRequests.remove(response.id)!.complete(response);
      } else {
        if (response.message != null) {
          _serverMessage = response.message;
          notifyListeners();
        }
      }
    } catch (e) {
      log('[DevPad.WS] Error decoding server message: $e');
    }
  }

  Future<ActionResponse> sendAction(
    String action, [
    Map<String, dynamic>? params,
  ]) async {
    if (_channel == null) {
      return const ActionResponse(
        status: 'error',
        error: 'Not connected to desktop companion.',
      );
    }

    final reqId = _uuid.v4();
    final completer = Completer<ActionResponse>();
    _pendingRequests[reqId] = completer;

    final payload = {
      'id': reqId,
      'action': action,
      ...?params,
    };

    try {
      log('[DevPad.WS] Sending action: $action (id: $reqId)');
      _channel!.sink.add(json.encode(payload));
    } catch (e) {
      _pendingRequests.remove(reqId);
      return ActionResponse(status: 'error', error: e.toString());
    }

    // Timeout after 8 seconds
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _pendingRequests.remove(reqId);
        return const ActionResponse(
          status: 'error',
          error: 'Request timed out waiting for desktop companion response.',
        );
      },
    );
  }

  Future<ActionResponse> insertText({
    required String text,
    required String profile,
    bool force = false,
  }) async {
    return sendAction('insert_text', {
      'text': text,
      'profile': profile,
      'force': force,
    });
  }

  Future<ActionResponse> ping() async {
    return sendAction('ping');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
