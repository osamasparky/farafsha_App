import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../router/app_router.dart';

class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._internal();
  DeepLinkService._internal();

  static const MethodChannel _channel = MethodChannel('com.farafsha.app/deeplink');
  bool _initialized = false;
  String? _pendingRoomCode;

  /// استهلاك رمز الغرفة المعلق عند فتح التطبيق من رابط خارجي (Cold Start)
  String? consumePendingRoomCode() {
    final code = _pendingRoomCode;
    _pendingRoomCode = null;
    return code;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. الاستماع للروابط الجديدة القادمة أثناء عمل التطبيق
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onLink') {
        final link = call.arguments?.toString();
        if (link != null && link.isNotEmpty) {
          _handleLinkString(link, isColdStart: false);
        }
      }
    });

    // 2. فحص الرابط الذي فتح التطبيق وهو مغلق (Cold Start)
    try {
      final initialLink = await _channel.invokeMethod<String>('getInitialLink');
      if (initialLink != null && initialLink.isNotEmpty) {
        _handleLinkString(initialLink, isColdStart: true);
      }
    } catch (e) {
      debugPrint('⚠️ Initial link check error: $e');
    }
  }

  void _handleLinkString(String link, {required bool isColdStart}) {
    debugPrint('🔗 DeepLink received: $link');
    final uri = Uri.tryParse(link);
    if (uri == null) return;

    String? roomCode;

    // النمط 1: https://farafsha.com/join/123456
    if (uri.pathSegments.contains('join')) {
      final joinIndex = uri.pathSegments.indexOf('join');
      if (joinIndex + 1 < uri.pathSegments.length) {
        roomCode = uri.pathSegments[joinIndex + 1];
      }
    }
    // النمط 2: farafsha://join/123456
    else if (uri.scheme == 'farafsha' && uri.host == 'join' && uri.pathSegments.isNotEmpty) {
      roomCode = uri.pathSegments.first;
    }
    // النمط 3: farafsha://join?code=123456
    else if (uri.scheme == 'farafsha' && uri.host == 'join') {
      roomCode = uri.queryParameters['code'];
    }

    // المعلمة البديلة: ?code=123456
    roomCode ??= uri.queryParameters['code'];

    if (roomCode != null && roomCode.isNotEmpty) {
      final cleanCode = roomCode.replaceAll(RegExp(r'\D'), '');
      if (cleanCode.length >= 4) {
        _pendingRoomCode = cleanCode;
        if (!isColdStart) {
          debugPrint('🎯 Navigating directly to /join-room with code: $cleanCode');
          _pendingRoomCode = null;
          appRouter.push('/join-room?code=$cleanCode');
        }
      }
    }
  }
}
