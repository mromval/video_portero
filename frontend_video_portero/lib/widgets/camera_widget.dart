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
    // 1. Crear el reproductor
    player = Player();
    // 2. Crear el controlador de video
    controller = VideoController(player);
    // 3. Cargar la URL RTSP
    player.open(Media(widget.rtspUrl), play: true);
  }

  @override
  void dispose() {
    // ¡Muy importante liberar memoria al cerrar!
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Fondo negro mientras carga
      child: Center(
        child: Video(
          controller: controller,
          fit: BoxFit.cover, // Llenar la pantalla (o contain para ver bordes)
          controls: NoVideoControls, // Sin barra de progreso (es en vivo)
        ),
      ),
    );
  }
}