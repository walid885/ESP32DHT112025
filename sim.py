import paho.mqtt.client as mqtt
import time
import random

# --- MQTT Configuration ---
MQTT_BROKER_HOST = "localhost" # Use the IP where Mosquitto is running
MQTT_BROKER_PORT = 1883
MQTT_TOPIC = "sensor/dht11/data"
CLIENT_ID = "PythonSimulator"

# --- Setup MQTT Client ---
client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv311)

def on_connect(client, userdata, flags, rc):
    """Callback for when the client receives a CONNACK response from the broker."""
    if rc == 0:
        print("Connected to MQTT Broker!")
    else:
        print(f"Failed to connect, return code {rc}")

client.on_connect = on_connect
client.connect(MQTT_BROKER_HOST, MQTT_BROKER_PORT, 60)
client.loop_start() # Start a non-blocking loop for network traffic

# --- Data Simulation and Publishing Loop ---
try:
    while True:
        # Simulate DHT11 data (Temperature and Humidity)
        temperature = round(random.uniform(20.0, 30.0), 2)
        humidity = round(random.uniform(40.0, 60.0), 2)
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")

        # Format payload (e.g., JSON or comma-separated)
        payload = f'{{"timestamp": "{timestamp}", "temp": {temperature}, "humidity": {humidity}}}'

        # Publish the data
        client.publish(MQTT_TOPIC, payload, qos=1)
        print(f"Published to topic {MQTT_TOPIC}: {payload}")

        time.sleep(5) # Send data every 5 seconds

except KeyboardInterrupt:
    print("\nSimulation stopped by user.")
finally:
    client.loop_stop()
    client.disconnect()