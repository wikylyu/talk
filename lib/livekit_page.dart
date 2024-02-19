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

  late Room room;
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

    room = Room(
      roomOptions: roomOptions,
    );
    // room.addListener(() {});
    _listener = room.createListener();
    _listener?.on<TrackSubscribedEvent>((p0) {
      setState(() {});
    });
    _listener?.on<TrackUnsubscribedEvent>(
      (p0) {
        setState(() {});
      },
    );

    final token = await getToken();

    await room.connect("wss://livekit.wikylyu.xyz", token,
        roomOptions: roomOptions);
    try {
      // video will fail when running in ios simulator
      var localVideo =
          await LocalVideoTrack.createCameraTrack(const CameraCaptureOptions(
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h720_169,
      ));
      await room.localParticipant?.publishVideoTrack(localVideo);
    } catch (e) {
      debugPrint(e.toString());
    }

    try {
      var localAudio = await LocalAudioTrack.create();
      await room.localParticipant?.publishAudioTrack(localAudio);
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _listener?.dispose();
    room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    VideoTrack? remoteTrack;
    for (var participant in room.remoteParticipants.values) {
      if (participant.hasVideo) {
        remoteTrack = participant.videoTrackPublications[0].track;
        break;
      }
    }
    VideoTrack? localTrack = (room.localParticipant?.hasVideo ?? false)
        ? room.localParticipant?.videoTrackPublications[0].track
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
            child: SizedBox(
              width: 120,
              height: 180,
              child: TrackRenderWidget(track: localTrack),
            ),
          ),
        ],
      ),
    );
  }
}
