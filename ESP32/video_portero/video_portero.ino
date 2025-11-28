#include <WiFi.h>
#include "Sip.h"

// ==========================================
// CONFIGURACIÓN DE RED Y SERVIDOR
// ==========================================

// 1. Datos de tu WiFi (Router DD-WRT)
const char* ssid = "video_portero_wifi";
const char* password = "qwerty1234";

// 2. Datos de tu Servidor (Raspberry Pi All-in-One)
const char* sip_server_ip = "192.168.88.10"; 
const int sip_server_port = 5060;

// 3. Credenciales SIP del ESP32 (Definidas en MariaDB)
const char* sip_user = "portero";
const char* sip_pass = "portero123";

// 4. A quién llamar cuando toquen el timbre
const char* target_ext = "101"; 

// ==========================================
// HARDWARE
// ==========================================
const int BUTTON_PIN = 0; // Botón BOOT del ESP32
char sipBuf[2048];        // Buffer de datos

// Inicializar objeto SIP
Sip aSip(String(sip_server_ip), String(sip_server_ip), sip_server_port);

// ==========================================
// SETUP (Se ejecuta una vez al inicio)
// ==========================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n--- INICIANDO SISTEMA PORTERO ROMVAL ---");

  // --- DIAGNÓSTICO DE WIFI ---
  // Esto nos dirá POR QUÉ falla si no conecta
  WiFi.onEvent([](WiFiEvent_t event, WiFiEventInfo_t info){
      if (event == ARDUINO_EVENT_WIFI_STA_DISCONNECTED) {
          Serial.print("\n>>> ERROR DE CONEXION! Razon (Code): ");
          Serial.println(info.wifi_sta_disconnected.reason);
          // Code 201: No encuentra red (Antena/Frecuencia)
          // Code 202: Auth Fallida (Clave incorrecta)
          // Code 2:   Clave valida pero rechazada (Router estricto)
      }
  });

  // --- CONEXIÓN WIFI ---
  Serial.println("1. Limpiando configuraciones antiguas...");
  WiFi.disconnect(true);  // Borra credenciales pegadas en memoria
  delay(1000);

  Serial.print("2. Conectando a: ");
  Serial.println(ssid);
  
  // Configuramos modo estación explícitamente
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  int intentos = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    intentos++;
    if (intentos > 40) { // Si tras 20 seg no conecta, reiniciamos
       Serial.println("\n\n!! TIEMPO AGOTADO. Reiniciando ESP32...");
       ESP.restart();
    }
  }

  Serial.println("\n\n>>> WIFI CONECTADO EXITOSAMENTE! <<<");
  Serial.print("IP Asignada: ");
  Serial.println(WiFi.localIP());

  // --- INICIO SIP ---
  Serial.println("3. Iniciando Cliente SIP...");
  aSip.Init(String(sip_server_ip), sip_server_port, WiFi.localIP().toString(), 5060, String(sip_user), String(sip_pass));
  
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  Serial.println(">>> SISTEMA LISTO. Presiona BOOT para llamar.");
}

// ==========================================
// LOOP (Se repite infinitamente)
// ==========================================
void loop() {
  // Mantener comunicación con Asterisk
  aSip.Processing(sipBuf);

  // Leer Botón (Lógica invertida: LOW es presionado)
  if (digitalRead(BUTTON_PIN) == LOW) {
    Serial.println("\n>> TIMBRE TOCADO! Llamando al " + String(target_ext) + "...");
    
    aSip.Dial(String(target_ext));
    
    // Esperar 2 segundos para no spammear llamadas
    delay(2000);
  }
}