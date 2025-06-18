import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hushmate/core/utils/logger.dart';

class CallService {
  static const String appId = '793f326a5d3446f890237d81c3d0d92b'; 
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isInCall = false;
  bool _isAudioCall = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC Engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Enable video module
    await _engine!.enableVideo();
    await _engine!.enableAudio();

    _isInitialized = true;
    AppLogger.info('✅ Call service initialized');
  }

  Future<void> startCall(String channelName, bool isAudioOnly) async {
    if (!_isInitialized) await initialize();

    _isAudioCall = isAudioOnly;
    _isInCall = true;

    // Set client role
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Join channel
    await _engine!.joinChannel(
      token: '', // Add token if you have token authentication enabled
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );

    AppLogger.info('✅ Joined call channel: $channelName');
  }

  Future<void> endCall() async {
    if (!_isInCall) return;

    await _engine?.leaveChannel();
    _isInCall = false;
    AppLogger.info('✅ Left call channel');
  }

  void dispose() {
    _engine?.release();
    _isInitialized = false;
    AppLogger.info('✅ Call service disposed');
  }

  bool get isInCall => _isInCall;
  bool get isAudioCall => _isAudioCall;
  RtcEngine? get engine => _engine;
} 