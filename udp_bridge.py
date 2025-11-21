import socket

# --- CONFIGURACIÓN ---
LOCAL_PORT = 5060
TARGET_IP = "100.81.27.88" # La IP Tailscale de tu CasaOS
TARGET_PORT = 5060

def run_bridge():
    # Creamos un socket para escuchar al ESP32
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", LOCAL_PORT))
    print(f"🌉 Puente UDP Activo en puerto {LOCAL_PORT}")
    print(f"🚀 Reenviando todo a {TARGET_IP}:{TARGET_PORT}")

    # Diccionario para recordar quién es el ESP32 (para devolverle la respuesta)
    esp32_addr = None

    while True:
        data, addr = sock.recvfrom(4096)
        
        # Si el paquete viene del Servidor (CasaOS), se lo mandamos al ESP32
        if addr[0] == TARGET_IP:
            if esp32_addr:
                sock.sendto(data, esp32_addr)
                # print(f"<-- Respuesta del Servidor enviada al ESP32")
        
        # Si el paquete NO es del servidor, asumimos que es del ESP32
        else:
            esp32_addr = addr # Guardamos la dirección del ESP32
            sock.sendto(data, (TARGET_IP, TARGET_PORT))
            print(f"--> Paquete del ESP32 ({addr[0]}) enviado a CasaOS")

if __name__ == "__main__":
    run_bridge()