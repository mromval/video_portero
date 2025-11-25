import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';
import 'package:media_kit/media_kit.dart';
import 'services/sip_service.dart';
import 'widgets/camera_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // <--- AGREGAR ESTO
  MediaKit.ensureInitialized();              // <--- Y ESTO (VITAL)
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
  
  // --- TUS DATOS ---
  final String _serverIP = '100.81.27.88'; 
  final String _extension = '201'; 
  final String _password = '1234';

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

  // --- LISTENERS ---
  @override
  void registrationStateChanged(RegistrationState state) {
    setState(() { _status = state.state.toString(); });
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("ESTADO LLAMADA: ${state.state}");
    
    setState(() {
      _currentCall = call; // Guardamos la llamada activa
    });

    // Si entra una llamada, mostramos la alerta o cambiamos la UI
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
        child: _currentCall == null || _currentCall!.state == CallStateEnum.ENDED
            ? _buildPantallaConexion() // Si no hay llamada, muestra conectar
            : _buildPantallaLlamada(), // Si hay llamada, muestra botones
      ),
    );
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
      ],
    );
  }

  Widget _buildPantallaLlamada() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("📞 LLAMADA ENTRANTE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text("De: ${_currentCall?.remote_display_name ?? 'Portero'}", style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón Colgar
            FloatingActionButton(
              onPressed: _colgar,
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            ),
            // Botón Contestar
            FloatingActionButton(
              onPressed: _contestar,
              backgroundColor: Colors.green,
              child: const Icon(Icons.call),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_currentCall!.state == CallStateEnum.CONFIRMED)
           const Text("🔴 EN LÍNEA - HABLANDO", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
      ],
    );
  }
}