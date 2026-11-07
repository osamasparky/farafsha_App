import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../network/api_service.dart';

class LiveKitVoiceService extends ChangeNotifier {
  static final LiveKitVoiceService instance = LiveKitVoiceService._internal();
  LiveKitVoiceService._internal();

  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMuted = false;
  bool _isSpeakerMuted = false;
  String? _currentRoomCode;
  List<String> _activeSpeakers = [];
  int _participantCount = 0;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isMuted => _isMuted;
  bool get isSpeakerMuted => _isSpeakerMuted;
  String? get currentRoomCode => _currentRoomCode;
  List<String> get activeSpeakers => _activeSpeakers;
  int get participantCount => _participantCount;

  /// تشغيل أو إيقاف الصوت تماماً بزر واحد
  Future<void> toggleVoiceConnection({
    required String roomCode,
    String? playerToken,
  }) async {
    if (_isConnected && _currentRoomCode == roomCode) {
      await leaveVoiceRoom();
    } else {
      await joinVoiceRoom(roomCode: roomCode, playerToken: playerToken);
    }
  }

  /// الانضمام إلى الغرفة الصوتية المباشرة
  Future<bool> joinVoiceRoom({
    required String roomCode,
    String? playerToken,
  }) async {
    if (_isConnected && _currentRoomCode == roomCode) return true;
    if (_isConnecting) return false;

    _isConnecting = true;
    notifyListeners();

    try {
      // 1. جلب التوكن وعنوان السيرفر من الباك إند
      final voiceData = await ApiService.instance.getVoiceToken(roomCode, token: playerToken);
      final serverUrl = voiceData['server_url'] as String? ?? 'wss://farafsha.com/livekit';
      final token = voiceData['token'] as String;

      // 2. مغادرة أي غرفة سابقة
      await leaveVoiceRoom();

      // 3. تهيئة غرفة LiveKit مع إعدادات الصوت فقط
      const roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: AudioPublishOptions(
          dtx: true,
        ),
      );

      _room = Room(roomOptions: roomOptions);
      _listener = _room!.createListener();

      _listener!
        ..on<ActiveSpeakersChangedEvent>((event) {
          _activeSpeakers = event.speakers
              .map((s) => s.name.isNotEmpty ? s.name : s.identity)
              .toList();
          notifyListeners();
        })
        ..on<ParticipantConnectedEvent>((_) {
          _updateCounts();
        })
        ..on<ParticipantDisconnectedEvent>((_) {
          _updateCounts();
        })
        ..on<TrackSubscribedEvent>((event) {
          if (event.track is RemoteAudioTrack && _isSpeakerMuted) {
            (event.track as RemoteAudioTrack).mediaStreamTrack.enabled = false;
          }
        })
        ..on<RoomDisconnectedEvent>((_) {
          _handleDisconnect();
        });

      // 4. الاتصال بالسيرفر
      await _room!.connect(serverUrl, token);

      // 5. تفعيل الميكروفون افتراضياً مع معالجة استثناءات إذن المايك
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
        _isMuted = false;
      } catch (micErr) {
        debugPrint('⚠️ Initial mic enable warning (device might start muted): $micErr');
        _isMuted = true;
      }
      _isSpeakerMuted = false;
      _currentRoomCode = roomCode;
      _updateCounts();

      debugPrint('🎙️ LiveKit Voice Room Connected: room_$roomCode');
      return true;
    } catch (e) {
      debugPrint('⚠️ LiveKit Voice Connect Error: $e');
      _handleDisconnect();
      return false;
    }
  }

  /// كتم أو تشغيل الميكروفون (Mute / Unmute Mic)
  Future<void> toggleMute() async {
    if (_room == null || !_isConnected) return;

    try {
      final newMute = !_isMuted;
      await _room!.localParticipant?.setMicrophoneEnabled(!newMute);
      _isMuted = newMute;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error toggling microphone: $e');
    }
  }

  /// كتم أو تشغيل صوت السماعة (Mute / Unmute Speaker)
  Future<void> toggleSpeakerMute() async {
    if (_room == null || !_isConnected) return;

    try {
      _isSpeakerMuted = !_isSpeakerMuted;
      for (final participant in _room!.remoteParticipants.values) {
        for (final pub in participant.audioTrackPublications) {
          pub.track?.mediaStreamTrack.enabled = !_isSpeakerMuted;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Error toggling speaker mute: $e');
    }
  }

  /// مغادرة الغرفة الصوتية وإيقاف الصوت
  Future<void> leaveVoiceRoom() async {
    try {
      await _room?.disconnect();
      await _room?.dispose();
    } catch (_) {}
    _handleDisconnect();
  }

  void _updateCounts() {
    if (_room != null) {
      _participantCount = (_room!.remoteParticipants.length) + 1;
      notifyListeners();
    }
  }

  void _handleDisconnect() {
    _listener?.dispose();
    _listener = null;
    _room = null;
    _isConnected = false;
    _isConnecting = false;
    _isMuted = false;
    _isSpeakerMuted = false;
    _currentRoomCode = null;
    _activeSpeakers = [];
    _participantCount = 0;
    notifyListeners();
  }
}
