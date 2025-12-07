#!/bin/bash

# --- Configuration ---
PROJECT_DIR="esp32_mqtt_simulator"
DB_NAME="sensor_data.db"

# --- 1. System Setup and Dependency Installation (requires sudo) ---
echo "## 1. Updating package lists and installing core dependencies (Mosquitto & Python tools)..."
# Check if running on a Debian/Ubuntu system
if [ -x "$(command -v apt-get)" ]; then
    sudo apt-get update
    # Install Mosquitto broker and Python 3 pip
    sudo apt-get install -y mosquitto python3-pip
    echo "System dependencies installed."
else
    echo "Warning: Not running on a Debian/Ubuntu-like system. Please manually install 'mosquitto' and 'python3-pip'."
fi

# --- 2. Create Project Directory ---
echo "## 2. Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# --- 3. Python Environment and Library Installation ---
echo "## 3. Installing required Python libraries..."
pip3 install paho-mqtt flask sqlite3 # sqlite3 is built-in but included for clarity
echo "Python dependencies installed successfully."

# --- 4. Database Setup ---
echo "## 4. Creating SQLite database file: $DB_NAME"
# The database will be fully setup by the data_storage.py script upon first run,
# but we create the file here for structure.
touch $DB_NAME
echo "Database file created."

# --- 5. Create Python Scripts ---

# A. Simulator Script (Replaces ESP32/DHT11)
echo "## 5. Creating simulator.py (MQTT Publisher)..."
cat << EOF > simulator.py
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
EOF
echo "simulator.py created."

# B. Data Storage Script (MQTT Subscriber & SQLite Writer)
echo "## 6. Creating data_storage.py (MQTT Subscriber)..."
cat << EOF > data_storage.py
import paho.mqtt.client as mqtt
import sqlite3
import json

# --- Database Configuration ---
DB_NAME = "$DB_NAME"
MQTT_BROKER_HOST = "localhost" 
MQTT_TOPIC = "sensor/dht11/data"
CLIENT_ID = "SQLiteSubscriber"

def setup_database():
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

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Subscriber connected to MQTT Broker.")
        client.subscribe(MQTT_TOPIC)
    else:
        print(f"Failed to connect, return code {rc}")

def on_message(client, userdata, msg):
    try:
        payload_str = msg.payload.decode()
        data = json.loads(payload_str)
        insert_reading(data)
    except Exception as e:
        print(f"Error processing message: {e}")

if __name__ == "__main__":
    setup_database()
    client = mqtt.Client(client_id=CLIENT_ID, protocol=mqtt.MQTTv311)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(MQTT_BROKER_HOST, 1883, 60)
    try:
        client.loop_forever() 
    except KeyboardInterrupt:
        print("\nSubscriber stopped by user.")
    finally:
        client.disconnect()
EOF
echo "data_storage.py created."

# C. Flask API Script (Frontend Access)
echo "## 7. Creating api.py (Flask Web API)..."
cat << EOF > api.py
from flask import Flask, jsonify
import sqlite3

app = Flask(__name__)
DB_NAME = "$DB_NAME"

def get_db_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/latest', methods=['GET'])
def get_latest_reading():
    conn = get_db_connection()
    reading = conn.execute("SELECT * FROM dht_readings ORDER BY id DESC LIMIT 1").fetchone()
    conn.close()
    
    if reading is None:
        return jsonify({"message": "No data available"}), 404
        
    return jsonify(dict(reading))

@app.route('/api/history/<int:count>', methods=['GET'])
def get_history(count):
    conn = get_db_connection()
    readings = conn.execute(
        "SELECT * FROM dht_readings ORDER BY id DESC LIMIT ?", 
        (count,)
    ).fetchall()
    conn.close()

    history = [dict(row) for row in readings]
    return jsonify(history)

if __name__ == '__main__':
    print("Flask API running on http://127.0.0.1:5000")
    app.run(host='0.0.0.0', port=5000)
EOF
echo "api.py created."

# --- 8. Final Instructions ---
echo " "
echo "========================================================"
echo "✅ SETUP COMPLETE! All files are in the '$PROJECT_DIR' directory."
echo "========================================================"
echo " "
echo "### To Run the Project (in three separate terminal windows):"
echo " "
echo "1. 🔌 Start the Mosquitto Broker (MQTT):"
echo "   mosquitto"
echo " "
echo "2. 💾 Start the Data Storage (MQTT Subscriber & DB Writer):"
echo "   python3 data_storage.py"
echo " "
echo "3. 🌡️ Start the Data Simulator (MQTT Publisher):"
echo "   python3 simulator.py"
echo " "
echo "4. 🌐 Start the Web API (Frontend Data Source):"
echo "   export FLASK_APP=api.py"
echo "   python3 api.py"
echo " "
echo "You can test the API by visiting http://127.0.0.1:5000/api/latest in your browser."