import paho.mqtt.client as mqtt
import sqlite3
import json
import time

# --- Database Configuration ---
DB_NAME = "sensor_data.db"
MQTT_BROKER_HOST = "localhost" 
MQTT_TOPIC = "sensor/dht11/data"
CLIENT_ID = "SQLiteSubscriber"

# --- Database Functions ---
def setup_database():
    """Connects to the DB and ensures the data table exists."""
    conn = sqlite3.connect(DB_NAME)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS dht_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL
        )
    """)
    conn.commit()
    conn.close()
    print(f"Database {DB_NAME} setup complete.")

def insert_reading(data):
    """Inserts a single sensor reading into the database."""
    try:
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO dht_readings (timestamp, temperature, humidity) VALUES (?, ?, ?)",
            (data['timestamp'], data['temp'], data['humidity'])
        )
        conn.commit()
        conn.close()
        print(f"Data saved to DB: T={data['temp']}, H={data['humidity']}")
    except Exception as e:
        print(f"Database error: {e}")

# --- MQTT Callbacks ---
def on_connect(client, userdata, flags, rc):
    """Subscribe to the topic upon successful connection."""
    if rc == 0:
        print("Subscriber connected to MQTT Broker.")
        client.subscribe(MQTT_TOPIC)
    else:
        print(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    """Process incoming MQTT messages."""
    try:
        # Decode and parse the JSON payload
        payload_str = msg.payload.decode()
        data = json.loads(payload_str)
        insert_reading(data)
    except Exception as e:
        print(f"Error processing message: {e}")
        print(f"Raw payload: {msg.payload}")


# --- Main Execution ---
if __name__ == "__main__":
    setup_database()
    
    client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv311)
    client.on_connect = on_connect
    client.on_message = on_message
    
    client.connect(MQTT_BROKER_HOST, 1883, 60)
    
    # Blocking call that processes network traffic, calls callbacks, and handles reconnecting.
    try:
        client.loop_forever() 
    except KeyboardInterrupt:
        print("\nSubscriber stopped by user.")
    finally:
        client.disconnect()