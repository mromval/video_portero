import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:media_kit/media_kit.dart'; 
import 'services/sip_service.dart';
import 'widgets/camera_widget.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); 
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> implements SipUaHelperListener {
  String _status = "Desconectado";
  Call? _currentCall;
  bool _testingCamera = false; // NUEVO: Variable para saber si estamos probando video
  
  // --- TUS DATOS ---
  final String _serverIP = '100.81.27.88'; 
  final String _extension = '201'; 
  final String _password = '1234';

  // --- TU CÁMARA ---
  // RECUERDA: El celular DEBE estar en el mismo WiFi que la cámara (192.168.2.x)
  final String _streamUrl = "rtsp://admin:Db930d71@192.168.2.186:554/onvif2";

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

  void _toggleCameraTest() {
    setState(() {
      _testingCamera = !_testingCamera; // Activa o desactiva el modo prueba
    });
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

  // --- LISTENERS ---
  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() { _status = state.state.toString(); });
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("ESTADO LLAMADA: ${state.state}");
    setState(() { _currentCall = call; });
    
    // Si entra llamada, apagamos el modo prueba para atender
    if (state.state == CallStateEnum.CALL_INITIATION) {
       setState(() { _testingCamera = false; });
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
        child: _decidirPantalla(),
      ),
    );
  }

  // Lógica para elegir qué mostrar
  Widget _decidirPantalla() {
    // 1. Si hay llamada activa -> Pantalla de Llamada
    if (_currentCall != null && _currentCall!.state != CallStateEnum.ENDED && _currentCall!.state != CallStateEnum.FAILED) {
      return _buildPantallaLlamada();
    }
    // 2. Si estamos probando cámara -> Pantalla de Video Test
    if (_testingCamera) {
      return _buildPantallaTestCamara();
    }
    // 3. Si no -> Pantalla de Conexión normal
    return _buildPantallaConexion();
  }

  // --- PANTALLA 1: CONEXIÓN + BOTÓN TEST ---
  Widget _buildPantallaConexion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Estado del Sistema:", style: TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        Text(_status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 30),
        ElevatedButton(onPressed: _conectar, child: const Text("Conectar a CasaOS")),
        const SizedBox(height: 50),
        
        // BOTÓN NUEVO PARA PROBAR VIDEO
        ElevatedButton.icon(
          onPressed: _toggleCameraTest,
          icon: const Icon(Icons.videocam),
          label: const Text("PROBAR CÁMARA AHORA"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(20)
          ),
        ),
      ],
    );
  }

  // --- PANTALLA NUEVA: SOLO VIDEO ---
  Widget _buildPantallaTestCamara() {
    return Stack(
      children: [
        CameraWidget(rtspUrl: _streamUrl),
        Positioned(
          bottom: 50,
          left: 0, right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _toggleCameraTest, // Volver atrás
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("CERRAR VIDEO", style: TextStyle(color: Colors.white)),
            ),
          ),
        )
      ],
    );
  }

  // --- PANTALLA 2: LLAMADA REAL ---
  Widget _buildPantallaLlamada() {
    return Stack(
      children: [
        Positioned.fill(child: CameraWidget(rtspUrl: _streamUrl)),
        Positioned.fill(child: Container(color: Colors.black45)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("📞 LLAMADA ENTRANTE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("De: ${_currentCall?.remote_display_name ?? 'Portero'}", style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 300),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _colgar,
                    backgroundColor: Colors.red,
                    heroTag: "btnColgar",
                    child: const Icon(Icons.call_end),
                  ),
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