import 'package:sip_ua/sip_ua.dart';

class SIPService implements SipUaHelperListener {
  // Singleton
  static final SIPService _instance = SIPService._internal();
  static SIPService get instance => _instance;
  
  final SIPUAHelper _helper = SIPUAHelper();
  
  SIPService._internal() {
    _helper.addSipUaHelperListener(this);
  }

  SIPUAHelper get helper => _helper;

void register(String extension, String password, String serverIP) {
    final UaSettings settings = UaSettings();

    // 1. DEFINIR EL TIPO DE TRANSPORTE (Esto es lo que probablemente faltaba)
    settings.transportType = TransportType.WS; 

    // 2. Configuración de Red
    settings.webSocketUrl = 'ws://$serverIP:9088/ws';
    settings.uri = 'sip:$extension@$serverIP';
    
    // 3. Credenciales
    settings.authorizationUser = extension;
    settings.password = password;
    settings.displayName = "Depto $extension";
    
    // 4. Configuración Técnica Extra
    settings.userAgent = 'Dart SIP Client v1.0';
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.register = true; // Confirmamos que queremos registrarnos
    
    // 5. Configuración WebRTC/Seguridad
    settings.webSocketSettings.allowBadCertificate = true; 
    settings.webSocketSettings.userAgent = 'Dart SIP Client v1.0';
    
    // 6. Evitar nulos en listas (Blindaje extra)
    settings.iceServers = []; 

    _helper.start(settings);
  }
  // --- MÉTODOS OBLIGATORIOS (NOMBRES CORREGIDOS) ---

  @override
  void transportStateChanged(TransportState state) {
    print("Transporte: ${state.state}");
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print("Registro: ${state.state}");
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("Llamada: ${state.state}");
  }
  
  @override
  void onNewMessage(SIPMessageRequest msg) {
    // Este sí lleva 'on'
  }
  
  @override
  void onNewNotify(Notify ntf) {
    // Este sí lleva 'on'
  }
  
  @override
  void onNewReinvite(ReInvite event) {
    // TODO: implement onNewReinvite
  }
}