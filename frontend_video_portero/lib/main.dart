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
  bool _testingCamera = false;
  
  // --- DATOS DEL SERVIDOR (ALL-IN-ONE) ---
  final String _serverIP = '192.168.88.10';  // Tu Raspberry Pi
  final String _extension = '101';           // El usuario en DB
  final String _password = '101secret';

  // --- TU CÁMARA ---
  // Por ahora directo a la cámara para probar. 
  // OJO: Cambia la IP '192.168.88.XXX' por la IP real que le dio el router nuevo a tu cámara.
  final String _streamUrl = "rtsp://192.168.88.10:8554/portero_cam"; // <--- AJUSTAR IP CÁMARA

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
      _testingCamera = !_testingCamera; 
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
      appBar: AppBar(title: const Text("RomVal Portero")),
      body: Center(
        child: _decidirPantalla(),
      ),
    );
  }

  Widget _decidirPantalla() {
    if (_currentCall != null && _currentCall!.state != CallStateEnum.ENDED && _currentCall!.state != CallStateEnum.FAILED) {
      return _buildPantallaLlamada();
    }
    if (_testingCamera) {
      return _buildPantallaTestCamara();
    }
    return _buildPantallaConexion();
  }

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

  Widget _buildPantallaTestCamara() {
    return Stack(
      children: [
        CameraWidget(rtspUrl: _streamUrl),
        Positioned(
          bottom: 50,
          left: 0, right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _toggleCameraTest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("CERRAR VIDEO", style: TextStyle(color: Colors.white)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPantallaLlamada() {
    return Stack(
      children: [
        Positioned.fill(child: CameraWidget(rtspUrl: _streamUrl)),
        // Capa semitransparente para ver los controles mejor
        Positioned(
            bottom: 0, left: 0, right: 0, height: 200,
            child: Container(color: Colors.black54)
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("📞 LLAMADA ENTRANTE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("De: ${_currentCall?.remote_display_name ?? 'Portero'}", style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 50),
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
              const SizedBox(height: 50),
            ],
          ),
        ),
      ],
    );
  }
}