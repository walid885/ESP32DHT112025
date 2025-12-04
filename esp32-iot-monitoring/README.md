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
