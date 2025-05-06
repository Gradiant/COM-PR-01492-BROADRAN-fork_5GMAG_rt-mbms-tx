import zmq
import numpy as np
import struct

# Configuración del socket ZMQ
ZMQ_ADDR = "tcp://127.0.1.1:2152"  # Dirección del socket (debe coincidir con `tx_port` en srsENB)
OUTPUT_FILE = "/root/samples/iq_samples.dat"  # Archivo donde se guardarán las muestras I/Q
context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect(ZMQ_ADDR)
socket.setsockopt_string(zmq.SUBSCRIBE, "") 

print(f"######### Escuchando muestras I/Q en la IP y puerto: {ZMQ_ADDR} #########")

with open(OUTPUT_FILE, "wb") as f:
    try:
        while True:
            iq_data = socket.recv() 
            samples = np.frombuffer(iq_data, dtype=np.complex64)
            f.write(iq_data)
            print(f"Recibidas {len(samples)} muestras I/Q")
    except KeyboardInterrupt:
        print("Captura detenida. Archivo guardado:", OUTPUT_FILE)
