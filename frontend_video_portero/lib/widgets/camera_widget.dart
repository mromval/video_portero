import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CameraWidget extends StatefulWidget {
  final String rtspUrl;

  const CameraWidget({super.key, required this.rtspUrl});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    
    controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false, // Mantener false por ahora
      ),
    );

    // Escuchar errores
    player.stream.error.listen((error) {
      print("🚨 ERROR MEDIA_KIT: $error");
    });

    // ABRIR EN MODO COMPATIBILIDAD
    // Quitamos 'nobuffer' y 'analyzeduration' para dejar que detecte el formato
    player.open(
      Media(
        widget.rtspUrl,
        extras: {
          'rtsp_transport': 'tcp', // TCP sigue siendo vital para no perder paquetes
          // Si sigue fallando, prueba descomentar la siguiente línea para forzar ffmpeg a analizar más profundo:
          // 'probesize': '10000000', // 10MB de análisis
          // 'analyzeduration': '5000000', // 5 segundos de análisis
        },
      ),
      play: true,
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Video(
              controller: controller,
              fit: BoxFit.cover,
              controls: NoVideoControls,
            ),
          ),
          Center(
            child: StreamBuilder<bool>(
              stream: player.stream.buffering,
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return const CircularProgressIndicator(color: Colors.white);
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}