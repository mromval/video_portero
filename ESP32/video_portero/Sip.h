#ifndef Sip_h
#define Sip_h

#include "Arduino.h"
#include <WiFiUdp.h>

class Sip {
  public:
    Sip(String out, String ip, int port);
    void Init(String ip, int port, String myip, int myport, String user, String pass);
    void Processing(char* buf);
    void Dial(String number);
    
  private:
    String _out_ip;
    int _out_port;
    String _sip_ip;
    int _sip_port;
    String _my_ip;
    int _my_port;
    String _sip_user;
    String _sip_pass;
    
    // Variables para mantener estado de la llamada
    String _call_id;
    String _tag;
    String _branch;
    
    // Guarda el número al que estamos intentando llamar (para re-intentos con Auth)
    String _last_dialed_number; 
    
    uint32_t iAuthCnt;
    
    WiFiUDP Udp;
    
    void Send(String data);
    String GetMD5(String data);
    void AddSipLine(String& str, String key, String value);
    uint32_t Random();
};

#endif