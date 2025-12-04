# ESP32 DHT11 MQTT Simulator

## Installation

```bash
./install.sh
```

## Quick Start

### 1. Start Docker Environment
```bash
./start_test_environment.sh
```

### 2. Run Simulator
```bash
# Single device
./run_single.sh

# Multiple devices
./run_multi.sh

# Test mode (60 seconds)
./run_test.sh
```

### 3. Verify Data
```bash
# Subscribe to MQTT topic
./verify_mqtt.sh

# Or use mosquitto_sub directly
mosquitto_sub -h localhost -t "esp32/sensors/dht11" -v
```

## Simulation Modes

- **normal**: Stable readings with small variations
- **increasing**: Gradual temperature increase
- **decreasing**: Gradual temperature decrease
- **spike**: Random anomalies (door opening, etc.)
- **random**: Completely random values

## Manual Usage

```bash
# Basic usage
python3 esp32_simulator.py

# Custom configuration
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --device esp32_001 \
    --interval 5 \
    --mode normal

# Multiple devices
python3 esp32_simulator.py --multi 5 --interval 3

# Time-limited test
python3 esp32_simulator.py --duration 60 --mode spike
```

## Parameters

- `--host`: MQTT broker hostname (default: localhost)
- `--port`: MQTT broker port (default: 1883)
- `--device`: Device ID (default: esp32_001)
- `--interval`: Publish interval in seconds (default: 5)
- `--duration`: Simulation duration in seconds (optional)
- `--mode`: Simulation mode (normal/increasing/decreasing/spike/random)
- `--multi`: Number of devices for multi-device simulation

## Monitoring

### MQTT Messages
```bash
mosquitto_sub -h localhost -t "esp32/sensors/dht11" -v
```

### Node-RED
- http://localhost:1880
- View flow and debug output

### Elasticsearch Query
```bash
curl -X GET "http://localhost:9200/sensor-data-*/_search?pretty" \
  -H 'Content-Type: application/json' -d'
{
  "size": 10,
  "sort": [{"@timestamp": "desc"}]
}'
```

### Grafana Dashboard
- http://localhost:3000 (admin/admin)
- Create visualizations from Elasticsearch data

## Troubleshooting

### Broker Connection Failed
```bash
# Check if broker is running
docker ps | grep mosquitto

# Check broker logs
docker logs mqtt-broker

# Test connection
mosquitto_pub -h localhost -t test -m "hello"
```

### No Data in Elasticsearch
```bash
# Check Node-RED logs
docker logs nodered

# Verify Elasticsearch
curl http://localhost:9200/_cat/indices?v

# Check if data is flowing
curl http://localhost:9200/sensor-data-*/_count
```

## Example Output

```
[14:32:15] [esp32_001] T:23.4°C H:58.2% HI:23.8°C | Mode: normal
[14:32:20] [esp32_001] T:23.6°C H:57.9% HI:24.0°C | Mode: normal
[14:32:25] [esp32_001] T:23.3°C H:58.5% HI:23.7°C | Mode: normal
```

## Stop Simulator

Press `Ctrl+C` to stop the simulator gracefully.
