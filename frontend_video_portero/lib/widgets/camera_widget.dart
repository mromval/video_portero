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
    
    // 1. Configuración del controlador: Usamos aceleración por hardware para fluidez
    controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true, 
      ),
    );

    // 2. ABRIR CON MODO "BAJA LATENCIA" (Low Latency)
    // Estos parámetros son vitales para que sea "en vivo" y no con retraso
    player.open(
      Media(
        widget.rtspUrl,
        extras: {
          'rtsp_transport': 'tcp', // TCP evita píxeles grises/verdes si el wifi falla
          'fflags': 'nobuffer',    // ¡IMPORTANTE! No guardar buffer, reproducir YA
          'analyzeduration': '0',  // No analizar el stream, mostrar directo
          'probesize': '32',       // Mínimo análisis de paquetes para arranque rápido
        },
      ),
      play: true,
    );
  }

  @override
  void dispose() {
    // ¡Muy importante liberar memoria al cerrar la llamada!
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Fondo negro estético
      child: Center(
        child: Video(
          controller: controller,
          fit: BoxFit.cover, // 'cover' llena la pantalla, 'contain' muestra bordes negros
          controls: NoVideoControls, // Ocultamos barra de play/pausa
        ),
      ),
    );
  }
}