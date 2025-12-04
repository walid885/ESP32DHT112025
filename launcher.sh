#!/bin/bash

# ESP32-DHT11-MQTT-Elasticsearch Project Setup Script
# Automated deployment with Docker orchestration

set -e

PROJECT_ROOT="esp32-iot-monitoring"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=================================================="
echo "ESP32 IoT Monitoring System - Setup"
echo "=================================================="

# Create directory structure
echo "[1/8] Creating project structure..."
mkdir -p ${PROJECT_ROOT}/{docker,nodered,grafana,esp32,scripts,logs,data}
mkdir -p ${PROJECT_ROOT}/docker/{mosquitto,elasticsearch,kibana}
mkdir -p ${PROJECT_ROOT}/nodered/data
mkdir -p ${PROJECT_ROOT}/grafana/{dashboards,provisioning}
mkdir -p ${PROJECT_ROOT}/esp32/src

cd ${PROJECT_ROOT}

# Generate docker-compose.yml
echo "[2/8] Generating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: mqtt-broker
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./docker/mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - ./docker/mosquitto/data:/mosquitto/data
      - ./docker/mosquitto/log:/mosquitto/log
    networks:
      - iot-network

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.11.0
    container_name: elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - cluster.name=iot-cluster
      - bootstrap.memory_lock=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    ports:
      - "9200:9200"
      - "9300:9300"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    networks:
      - iot-network

  kibana:
    image: docker.elastic.co/kibana/kibana:8.11.0
    container_name: kibana
    restart: unless-stopped
    ports:
      - "5601:5601"
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - iot-network

  nodered:
    image: nodered/node-red:latest
    container_name: nodered
    restart: unless-stopped
    ports:
      - "1880:1880"
    volumes:
      - ./nodered/data:/data
    environment:
      - TZ=UTC
    depends_on:
      - mosquitto
      - elasticsearch
    networks:
      - iot-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
      - ./grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-elasticsearch-datasource
    depends_on:
      - elasticsearch
    networks:
      - iot-network

networks:
  iot-network:
    driver: bridge

volumes:
  elasticsearch-data:
  grafana-data:
EOF

# Generate Mosquitto configuration
echo "[3/8] Generating MQTT Broker configuration..."
mkdir -p docker/mosquitto/{data,log}
cat > docker/mosquitto/mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_dest stdout
log_type all
connection_messages true
EOF

# Generate Node-RED flows
echo "[4/8] Generating Node-RED flows..."
cat > nodered/data/flows.json << 'EOF'
[
  {
    "id": "mqtt_in",
    "type": "mqtt in",
    "z": "flow1",
    "name": "ESP32 Sensor Data",
    "topic": "esp32/sensors/dht11",
    "qos": "1",
    "datatype": "json",
    "broker": "mqtt_broker",
    "x": 150,
    "y": 100,
    "wires": [["process_data"]]
  },
  {
    "id": "process_data",
    "type": "function",
    "z": "flow1",
    "name": "Process & Enrich",
    "func": "const payload = msg.payload;\nconst timestamp = new Date().toISOString();\n\nmsg.payload = {\n  '@timestamp': timestamp,\n  device_id: payload.device_id || 'esp32_001',\n  temperature: parseFloat(payload.temperature),\n  humidity: parseFloat(payload.humidity),\n  heat_index: parseFloat(payload.heat_index),\n  location: 'lab_01',\n  status: 'active'\n};\n\nreturn msg;",
    "x": 350,
    "y": 100,
    "wires": [["es_out", "debug_out"]]
  },
  {
    "id": "es_out",
    "type": "elasticsearch",
    "z": "flow1",
    "name": "To Elasticsearch",
    "cluster": "http://elasticsearch:9200",
    "index": "sensor-data-{now/d}",
    "x": 550,
    "y": 100,
    "wires": [[]]
  },
  {
    "id": "debug_out",
    "type": "debug",
    "z": "flow1",
    "name": "Debug Output",
    "x": 550,
    "y": 160,
    "wires": []
  },
  {
    "id": "mqtt_broker",
    "type": "mqtt-broker",
    "name": "Local Mosquitto",
    "broker": "mosquitto",
    "port": "1883",
    "clientid": "nodered_client",
    "autoConnect": true
  }
]
EOF

# Generate ESP32 Arduino Code
echo "[5/8] Generating ESP32 firmware..."
cat > esp32/src/esp32_dht11_mqtt.ino << 'EOF'
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

// Configuration
#define DHTPIN 4          // GPIO4 for DHT11 data pin
#define DHTTYPE DHT11
#define DEVICE_ID "esp32_001"

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Broker
const char* mqtt_server = "YOUR_MQTT_BROKER_IP";
const int mqtt_port = 1883;
const char* mqtt_topic = "esp32/sensors/dht11";

// Objects
DHT dht(DHTPIN, DHTTYPE);
WiFiClient espClient;
PubSubClient client(espClient);

// Variables
unsigned long lastMsg = 0;
const long interval = 5000; // 5 seconds

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    String clientId = "ESP32Client-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  dht.begin();
  setup_wifi();
  client.setServer(mqtt_server, mqtt_port);
  
  Serial.println("ESP32 DHT11 MQTT Sensor Ready");
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > interval) {
    lastMsg = now;

    // Read sensor data
    float humidity = dht.readHumidity();
    float temperature = dht.readTemperature();

    if (isnan(humidity) || isnan(temperature)) {
      Serial.println("Failed to read from DHT sensor!");
      return;
    }

    // Calculate heat index
    float heatIndex = dht.computeHeatIndex(temperature, humidity, false);

    // Create JSON payload
    StaticJsonDocument<256> doc;
    doc["device_id"] = DEVICE_ID;
    doc["temperature"] = temperature;
    doc["humidity"] = humidity;
    doc["heat_index"] = heatIndex;
    doc["timestamp"] = millis();

    char jsonBuffer[256];
    serializeJson(doc, jsonBuffer);

    // Publish to MQTT
    if (client.publish(mqtt_topic, jsonBuffer)) {
      Serial.println("Data published:");
      Serial.println(jsonBuffer);
    } else {
      Serial.println("Publish failed");
    }
  }
}
EOF

# Generate Grafana dashboard provisioning
echo "[6/8] Generating Grafana provisioning..."
mkdir -p grafana/provisioning/{datasources,dashboards}

cat > grafana/provisioning/datasources/elasticsearch.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Elasticsearch
    type: elasticsearch
    access: proxy
    url: http://elasticsearch:9200
    database: "sensor-data-*"
    jsonData:
      timeField: "@timestamp"
      esVersion: "8.0.0"
      interval: Daily
      logMessageField: message
      logLevelField: level
    editable: true
EOF

cat > grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'ESP32 Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Generate deployment script
echo "[7/8] Generating deployment scripts..."
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
echo "Starting all services..."
docker-compose up -d
echo "Waiting for services to be ready..."
sleep 15
echo "Services deployed successfully!"
echo ""
echo "Access URLs:"
echo "- Node-RED: http://localhost:1880"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- Kibana: http://localhost:5601"
echo "- Elasticsearch: http://localhost:9200"
echo "- MQTT Broker: mqtt://localhost:1883"
EOF

cat > scripts/stop.sh << 'EOF'
#!/bin/bash
echo "Stopping all services..."
docker-compose down
EOF

cat > scripts/logs.sh << 'EOF'
#!/bin/bash
docker-compose logs -f $1
EOF

cat > scripts/status.sh << 'EOF'
#!/bin/bash
echo "Service Status:"
docker-compose ps
echo ""
echo "Elasticsearch Health:"
curl -s http://localhost:9200/_cluster/health?pretty
EOF

chmod +x scripts/*.sh

# Generate README
echo "[8/8] Generating documentation..."
cat > README.md << 'EOF'
# ESP32 IoT Monitoring System

## Architecture
- **ESP32 + DHT11**: Temperature/Humidity sensor
- **MQTT (Mosquitto)**: Message broker
- **Node-RED**: Data processing pipeline
- **Elasticsearch**: Time-series data storage
- **Grafana/Kibana**: Data visualization

## Quick Start

1. **Deploy Infrastructure**
   ```bash
   ./scripts/deploy.sh
   ```

2. **Configure ESP32**
   - Open `esp32/src/esp32_dht11_mqtt.ino`
   - Update WiFi credentials
   - Update MQTT broker IP
   - Upload to ESP32 using Arduino IDE

3. **Access Services**
   - Node-RED: http://localhost:1880
   - Grafana: http://localhost:3000
   - Kibana: http://localhost:5601

## ESP32 Wiring
- DHT11 VCC → ESP32 3.3V
- DHT11 GND → ESP32 GND
- DHT11 DATA → ESP32 GPIO4

## Commands
- Deploy: `./scripts/deploy.sh`
- Stop: `./scripts/stop.sh`
- Logs: `./scripts/logs.sh [service_name]`
- Status: `./scripts/status.sh`
EOF

echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "Project structure created at: ${PROJECT_ROOT}/"
echo ""
echo "Next steps:"
echo "1. cd ${PROJECT_ROOT}"
echo "2. ./scripts/deploy.sh"
echo "3. Configure ESP32 firmware in esp32/src/"
echo "4. Access Node-RED at http://localhost:1880"
echo ""
echo "=================================================="