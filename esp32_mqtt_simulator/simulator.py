import paho.mqtt.client as mqtt
import time
import random
import json

# --- MQTT Configuration ---
MQTT_BROKER_HOST = "localhost" 
MQTT_BROKER_PORT = 1883
MQTT_TOPIC = "sensor/dht11/data"
CLIENT_ID = "PythonSimulator"

# --- Setup MQTT Client ---
client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv311)

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT Broker!")
    else:
        print(f"Failed to connect, return code {rc}")

client.on_connect = on_connect
client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, 60)
client.loop_start() 

# --- Data Simulation and Publishing Loop ---
try:
    while True:
        temperature = round(random.uniform(20.0, 30.0), 2)
        humidity = round(random.uniform(40.0, 60.0), 2)
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

        payload = json.dumps({"timestamp": timestamp, "temp": temperature, "humidity": humidity})

        client.publish(MQTT_TOPIC, payload, qos=1)
        print(f"Published to topic {MQTT_TOPIC}: {payload}")

        time.sleep(5) 

except KeyboardInterrupt:
    print("\nSimulation stopped by user.")
finally:
    client.loop_stop()
    client.disconnect()
