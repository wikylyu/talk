import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:talk/api.dart';

class TrackRenderWidget extends StatelessWidget {
  final VideoTrack? track;
  const TrackRenderWidget({super.key, required this.track});
  @override
  Widget build(BuildContext context) {
    return track != null
        ? VideoTrackRenderer(
            track!,
            fit: rtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        : Container(
            color: Colors.grey,
          );
  }
}

class LivekitPage extends StatefulWidget {
  const LivekitPage({Key? key}) : super(key: key);

  @override
  createState() => _LivekitPageState();
}

class _LivekitPageState extends State<LivekitPage> {
  @override
  void initState() {
    super.initState();

    _connect();
  }

  late Room _room;
  late EventsListener<RoomEvent>? _listener;

  _connect() async {
    final roomOptions = RoomOptions(
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          deviceId: '',
          cameraPosition: CameraPosition.back,
          params: VideoParametersPresets.h720_169,
        ),
        defaultAudioCaptureOptions: const AudioCaptureOptions(
          deviceId: '',
          noiseSuppression: true,
          echoCancellation: true,
          autoGainControl: true,
          highPassFilter: true,
          typingNoiseDetection: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          videoEncoding: VideoParametersPresets.h720_169.encoding,
          videoSimulcastLayers: [
            VideoParametersPresets.h180_169,
            VideoParametersPresets.h360_169,
          ],
        ),
        defaultAudioPublishOptions: const AudioPublishOptions(
          dtx: true,
        ));

    _room = Room(
      roomOptions: roomOptions,
    );
    _listener = _room.createListener();
    _listener?.on<TrackSubscribedEvent>((p0) {
      setState(() {});
    });
    _listener?.on<TrackUnsubscribedEvent>(
      (p0) {
        setState(() {});
      },
    );
    _listener?.on<LocalTrackPublishedEvent>(
      (p0) {
        setState(() {});
      },
    );

    final token = await getToken();

    await _room.connect("wss://live.chainboats.com", token,
        roomOptions: roomOptions);
    try {
      var localVideo = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          params: VideoParametersPresets.h720_169,
        ),
      );
      _localVideoTrackPublication =
          await _room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      debugPrint(e.toString());
    }

    try {
      await _room.localParticipant?.setMicrophoneEnabled(true);
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() {});
  }

  CameraPosition _cameraPosition = CameraPosition.front;
  bool _muted = false;
  LocalTrackPublication<LocalVideoTrack>? _localVideoTrackPublication;

  @override
  void dispose() {
    _listener?.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    VideoTrack? remoteTrack;
    for (var participant in _room.remoteParticipants.values) {
      if (participant.hasVideo) {
        remoteTrack = participant.videoTrackPublications[0].track;
        break;
      }
    }
    VideoTrack? localTrack = (_room.localParticipant?.hasVideo ?? false)
        ? _room.localParticipant?.videoTrackPublications[0].track
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVEKIT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          TrackRenderWidget(track: remoteTrack),
          Positioned(
            right: 20,
            top: 20,
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 180,
                  child: TrackRenderWidget(track: localTrack),
                ),
                const SizedBox(
                  width: 10,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.cameraswitch),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    IconButton(
                      onPressed: _switchMute,
                      icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _switchCamera() async {
    _cameraPosition = _cameraPosition == CameraPosition.front
        ? CameraPosition.back
        : CameraPosition.front;
    try {
      if (_localVideoTrackPublication != null) {
        _room.localParticipant
            ?.removePublishedTrack(_localVideoTrackPublication!.sid);
      }
      var localVideo = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          cameraPosition: _cameraPosition,
          params: VideoParametersPresets.h720_169,
        ),
      );
      _localVideoTrackPublication =
          await _room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() {});
  }

  _switchMute() async {
    _muted = !_muted;
    _room.localParticipant?.setMicrophoneEnabled(!_muted);
    setState(() {});
  }
}
