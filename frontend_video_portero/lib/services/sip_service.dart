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

    // IMPORTANTE: Usamos WS (no WSS aún) y el puerto 8088
    settings.transportType = TransportType.WS; 
    settings.webSocketUrl = 'ws://$serverIP:8088/ws';
    settings.uri = 'sip:$extension@$serverIP';
    
    settings.authorizationUser = extension;
    settings.password = password;
    settings.displayName = "Depto $extension";
    
    settings.userAgent = 'RomVal App';
    settings.dtmfMode = DtmfMode.RFC2833;
    settings.register = true;
    
    // CRÍTICO PARA RED LOCAL: Permitir certificados sin SSL real
    settings.webSocketSettings.allowBadCertificate = true; 
    settings.webSocketSettings.userAgent = 'RomVal App';
    
    settings.iceServers = []; // Sin STUN para local (más rápido)

    _helper.start(settings);
  }

  // --- MÉTODOS OBLIGATORIOS (Listeners) ---

  @override
  void transportStateChanged(TransportState state) {
    print("📢 SIP Transporte: ${state.state}");
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print("✅ SIP Registro: ${state.state}");
  }

  @override
  void callStateChanged(Call call, CallState state) {
    print("📞 SIP Llamada: ${state.state}");
  }
  
  @override
  void onNewMessage(SIPMessageRequest msg) {}
  
  @override
  void onNewNotify(Notify ntf) {}
  
  @override
  void onNewReinvite(ReInvite event) {}
}