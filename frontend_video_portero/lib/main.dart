import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:media_kit/media_kit.dart'; // Importante para el video
import 'services/sip_service.dart';
import 'widgets/camera_widget.dart'; // Asegúrate de que este archivo exista en esa ruta

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // Inicializamos el motor de video
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> implements SipUaHelperListener {
  String _status = "Desconectado";
  Call? _currentCall; // Aquí guardamos la llamada entrante
  
  // --- TUS DATOS DE CONEXIÓN ---
  final String _serverIP = '100.81.27.88'; 
  final String _extension = '201'; 
  final String _password = '1234';

  // --- TU CÁMARA ONVIF (RTSP) ---
  // Nota: Para ver esto, el celular debe estar en la misma red WiFi que la cámara (192.168.2.x)
  final String _streamUrl = "rtsp://admin:Db930d71@192.168.2.186:554/onvif1";

  @override
  void initState() {
    super.initState();
    _pedirPermisos();
    SIPService.instance.helper.addSipUaHelperListener(this);
  }

  Future<void> _pedirPermisos() async {
    await [Permission.microphone, Permission.notification].request();
  }

  void _conectar() {
    SIPService.instance.register(_extension, _password, _serverIP);
  }

  // --- ACCIONES DE LLAMADA ---
  void _contestar() {
    if (_currentCall != null) {
      _currentCall!.answer(SIPService.instance.helper.buildCallOptions(true));
    }
  }

  void _colgar() {
    if (_currentCall != null) {
      _currentCall!.hangup();
    }
  }

  // --- LISTENERS DE SIP ---
  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() { _status = state.state.toString(); });
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("ESTADO LLAMADA: ${state.state}");
    
    setState(() {
      _currentCall = call; 
    });

    if (state.state == CallStateEnum.CALL_INITIATION) {
       print("🔔 ¡TIMBRE! Llamada entrante...");
    }
  }

  @override
  void transportStateChanged(TransportState state) {}
  @override
  void onNewMessage(SIPMessageRequest msg) {}
  @override
  void onNewNotify(Notify ntf) {}
  @override
  void onNewReinvite(ReInvite event) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Romval Portero")),
      body: Center(
        // Lógica para decidir qué pantalla mostrar: Conexión o Llamada
        child: _currentCall == null || _currentCall!.state == CallStateEnum.ENDED || _currentCall!.state == CallStateEnum.FAILED
            ? _buildPantallaConexion() 
            : _buildPantallaLlamada(), 
      ),
    );
  }

  // --- PANTALLA 1: CONEXIÓN ---
  Widget _buildPantallaConexion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Estado del Sistema:", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Text(_status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _conectar, child: const Text("Conectar a CasaOS")),
      ],
    );
  }

  // --- PANTALLA 2: LLAMADA CON VIDEO DE FONDO ---
  Widget _buildPantallaLlamada() {
    return Stack(
      children: [
        // CAPA 1: El Video de fondo (Cámara RTSP)
        Positioned.fill(
          child: CameraWidget(rtspUrl: _streamUrl),
        ),
        
        // CAPA 2: Un oscurecedor para que se lean las letras
        Positioned.fill(
          child: Container(color: Colors.black45),
        ),

        // CAPA 3: Los botones y textos
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("📞 LLAMADA ENTRANTE", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("De: ${_currentCall?.remote_display_name ?? 'Portero'}", 
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 300), // Espacio libre para ver la imagen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Colgar
                  FloatingActionButton(
                    onPressed: _colgar,
                    backgroundColor: Colors.red,
                    heroTag: "btnColgar",
                    child: const Icon(Icons.call_end),
                  ),
                  // Botón Contestar
                  FloatingActionButton(
                    onPressed: _contestar,
                    backgroundColor: Colors.green,
                    heroTag: "btnContestar",
                    child: const Icon(Icons.call),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_currentCall!.state == CallStateEnum.CONFIRMED)
                 const Text("🔴 EN LÍNEA - HABLANDO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      ],
    );
  }
}