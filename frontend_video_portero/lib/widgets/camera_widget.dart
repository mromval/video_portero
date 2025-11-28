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
        enableHardwareAcceleration: false, // Intentamos activar aceleración
      ),
    );

    player.stream.error.listen((error) {
      print("🚨 ERROR MEDIA_KIT: $error");
    });

    // CONFIGURACIÓN DE BAJA LATENCIA (REALTIME)
    player.open(
      Media(
        widget.rtspUrl,
        extras: {
          'rtsp_transport': 'tcp', 
          'fflags': 'nobuffer',      // Clave: No guardar buffer
          'analyzeduration': '0',    // Clave: No analizar
          'probesize': '32',         // Mínimo posible
          'dead_link_interval': '1', // Detectar caída rápido
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
      child: Center(
        child: Video(
          controller: controller,
          fit: BoxFit.cover,
          controls: NoVideoControls,
        ),
      ),
    );
  }
}