import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// خدمة الاتصال اللحظي WebSockets لغرف اللعب المتزامنة
/// متوافقة 100% مع Laravel Reverb والبروتوكول القياسي لـ Pusher
class RoomRealtimeService {
  static final RoomRealtimeService instance = RoomRealtimeService._internal();
  RoomRealtimeService._internal();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  bool _isInitialized = false;
  String? _currentRoomCode;

  // Callbacks للواجهات عند وصول الأحداث الحية
  Function(Map<String, dynamic>)? onPlayerJoined;
  Function(Map<String, dynamic>)? onGameStarted;
  Function(Map<String, dynamic>)? onRoundStarted;
  Function(Map<String, dynamic>)? onPlayerAnswered;
  Function(Map<String, dynamic>)? onRoundEnded;

  /// تهيئة الاتصال بخادم Laravel Reverb
  Future<void> init({
    String apiKey = 'lammah-key',
    String host = '127.0.0.1',
    int port = 8080,
    String cluster = 'mt1',
  }) async {
    if (_isInitialized) return;

    try {
      await _pusher.init(
        apiKey: apiKey,
        cluster: cluster,
        onEvent: _handleGlobalEvent,
        onError: (message, code, exception) {
          debugPrint("🔴 Realtime Error: $message (code: $code)");
        },
        onSubscriptionSucceeded: (channelName, data) {
          debugPrint("🟢 Subscribed to $channelName");
        },
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint("⚠️ Realtime Init failed: $e");
    }
  }

  /// الانضمام إلى قناة الغرفة المحددة
  Future<void> subscribeToRoom(String roomCode) async {
    await init();
    _currentRoomCode = roomCode;
    final channelName = 'room.$roomCode';

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleRoomEvent(event.eventName, event.data);
        },
      );
      await _pusher.connect();
    } catch (e) {
      debugPrint("⚠️ Failed to subscribe to $channelName: $e");
    }
  }

  /// مغادرة الغرفة وإلغاء الاشتراك
  Future<void> leaveRoom() async {
    if (_currentRoomCode != null) {
      await _pusher.unsubscribe(channelName: 'room.$_currentRoomCode');
      _currentRoomCode = null;
    }
  }

  /// معالجة أحداث اللعبة اللحظية
  void _handleRoomEvent(String eventName, dynamic rawData) {
    Map<String, dynamic> data = {};
    if (rawData is String) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {}
    } else if (rawData is Map<String, dynamic>) {
      data = rawData;
    }

    debugPrint("⚡ Realtime Event Received: $eventName -> $data");

    switch (eventName) {
      case 'player.joined':
        onPlayerJoined?.call(data);
        break;
      case 'game.started':
        onGameStarted?.call(data);
        break;
      case 'round.started':
        onRoundStarted?.call(data);
        break;
      case 'player.answered':
        onPlayerAnswered?.call(data);
        break;
      case 'round.ended':
        onRoundEnded?.call(data);
        break;
    }
  }

  void _handleGlobalEvent(PusherEvent event) {
    debugPrint("🔔 [Pusher Global Event] channel: ${event.channelName}, event: ${event.eventName}");
  }
}

