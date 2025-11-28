#include "Sip.h"
#include <MD5Builder.h>

Sip::Sip(String out, String ip, int port) {
  _out_ip = ip;
  _out_port = port;
  iAuthCnt = 0;
  _last_dialed_number = "";
}

void Sip::Init(String ip, int port, String myip, int myport, String user, String pass) {
  _sip_ip = ip;
  _sip_port = port;
  _my_ip = myip;
  _my_port = myport;
  _sip_user = user;
  _sip_pass = pass;
  
  _call_id = String(Random()) + String(Random()) + "@" + _my_ip;
  _tag = String(Random());
  _branch = "z9hG4bK" + String(Random());
  
  Udp.begin(_my_port);
}

void Sip::Dial(String number) {
  // Guardamos el número por si nos piden contraseña después
  _last_dialed_number = number;
  
  // Reiniciamos contador
  iAuthCnt = 0; 
  
  String p = "";
  AddSipLine(p, "INVITE sip:" + number + "@" + _sip_ip + " SIP/2.0", "");
  AddSipLine(p, "Via: SIP/2.0/UDP " + _my_ip + ":" + _my_port + ";branch=" + _branch, "");
  AddSipLine(p, "From: <sip:" + _sip_user + "@" + _sip_ip + ">;tag=" + _tag, "");
  AddSipLine(p, "To: <sip:" + number + "@" + _sip_ip + ">", "");
  AddSipLine(p, "Call-ID: " + _call_id, "");
  AddSipLine(p, "CSeq: " + String(iAuthCnt + 1) + " INVITE", "");
  AddSipLine(p, "Contact: <sip:" + _sip_user + "@" + _my_ip + ":" + _my_port + ">", "");
  AddSipLine(p, "Max-Forwards: 70", "");
  AddSipLine(p, "User-Agent: ESP32-Portero-RomVal", ""); // Personalizado ;)
  AddSipLine(p, "Content-Type: application/sdp", "");
  AddSipLine(p, "Content-Length: 0", "");
  p += "\r\n";
  
  Send(p);
}

// Helper para parsear texto
String extractValue(String data, String key) {
  int start = data.indexOf(key);
  if (start == -1) return "";
  start += key.length();
  if (data.charAt(start) == '"') start++; 
  int end = data.indexOf('"', start);
  if (end == -1) end = data.indexOf(',', start); 
  if (end == -1) end = data.indexOf('\r', start); 
  return data.substring(start, end);
}

void Sip::Processing(char* buf) {
  int packetSize = Udp.parsePacket();
  if (packetSize) {
    int len = Udp.read(buf, 2048);
    buf[len] = 0;
    String packet = String(buf);
    
    // DEBUG: Descomentar si quieres ver todo el tráfico
    // Serial.println(packet); 

    // DETECTAR DESAFÍO DE SEGURIDAD (401 Unauthorized)
    if (packet.indexOf("401 Unauthorized") > 0 && iAuthCnt == 0) {
        Serial.println("SIP: Asterisk pide Auth. Calculando hash para llamar a " + _last_dialed_number + "...");
        
        String nonce = extractValue(packet, "nonce=\"");
        String realm = extractValue(packet, "realm=\"");
        if (nonce == "") nonce = extractValue(packet, "nonce=");
        
        // --- CÁLCULO MD5 DIGEST ---
        // HA1 = MD5(user:realm:pass)
        String ha1_str = _sip_user + ":" + realm + ":" + _sip_pass;
        String ha1 = GetMD5(ha1_str);
        
        // HA2 = MD5(method:uri) -> INVITE:sip:NUMERO@IP
        String uri = "sip:" + _last_dialed_number + "@" + _sip_ip;
        String ha2_str = "INVITE:" + uri;
        String ha2 = GetMD5(ha2_str);
        
        // RESPONSE = MD5(HA1:nonce:HA2)
        String response_str = ha1 + ":" + nonce + ":" + ha2;
        String response = GetMD5(response_str);
        
        // --- PASO 1: Enviar ACK al 401 ---
        String ack = "";
        AddSipLine(ack, "ACK " + uri + " SIP/2.0", "");
        AddSipLine(ack, "Via: SIP/2.0/UDP " + _my_ip + ":" + _my_port + ";branch=" + _branch, "");
        AddSipLine(ack, "From: <sip:" + _sip_user + "@" + _sip_ip + ">;tag=" + _tag, "");
        AddSipLine(ack, "To: <sip:" + _last_dialed_number + "@" + _sip_ip + ">;tag=" + extractValue(packet, "tag="), "");
        AddSipLine(ack, "Call-ID: " + _call_id, "");
        AddSipLine(ack, "CSeq: 1 ACK", "");
        AddSipLine(ack, "Content-Length: 0", "");
        ack += "\r\n";
        Send(ack);
        
        delay(50); 
        
        // --- PASO 2: Enviar INVITE con Credenciales ---
        iAuthCnt++;
        String p = "";
        AddSipLine(p, "INVITE " + uri + " SIP/2.0", "");
        AddSipLine(p, "Via: SIP/2.0/UDP " + _my_ip + ":" + _my_port + ";branch=" + _branch + "2", ""); 
        AddSipLine(p, "From: <sip:" + _sip_user + "@" + _sip_ip + ">;tag=" + _tag, "");
        AddSipLine(p, "To: <sip:" + _last_dialed_number + "@" + _sip_ip + ">", "");
        AddSipLine(p, "Call-ID: " + _call_id, "");
        AddSipLine(p, "CSeq: " + String(iAuthCnt + 1) + " INVITE", "");
        AddSipLine(p, "Contact: <sip:" + _sip_user + "@" + _my_ip + ":" + _my_port + ">", "");
        
        // Header Authorization
        String authHeader = "Digest username=\"" + _sip_user + "\", realm=\"" + realm + "\", nonce=\"" + nonce + "\", uri=\"" + uri + "\", response=\"" + response + "\", algorithm=MD5";
        AddSipLine(p, "Authorization", authHeader);
        
        AddSipLine(p, "Max-Forwards: 70", "");
        AddSipLine(p, "User-Agent: ESP32-Portero-RomVal", "");
        AddSipLine(p, "Content-Type: application/sdp", "");
        AddSipLine(p, "Content-Length: 0", "");
        p += "\r\n";
        
        Serial.println("SIP: Enviando respuesta con Auth...");
        Send(p);
    }
  }
}

void Sip::Send(String data) {
  Udp.beginPacket(_out_ip.c_str(), _out_port);
  Udp.write((const uint8_t*)data.c_str(), data.length());
  Udp.endPacket();
}

void Sip::AddSipLine(String& str, String key, String value) {
  if (value == "") str += key + "\r\n";
  else str += key + ": " + value + "\r\n";
}

uint32_t Sip::Random() {
  return esp_random();
}

String Sip::GetMD5(String data) {
  MD5Builder md5;
  md5.begin();
  md5.add(data);
  md5.calculate();
  return md5.toString();
}