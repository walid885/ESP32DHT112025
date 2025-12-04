#!/bin/bash

echo "Verifying MQTT Broker Connection..."
echo ""

# Check if mosquitto_sub is available
if ! command -v mosquitto_sub &> /dev/null; then
    echo "Installing mosquitto-clients..."
    sudo apt-get update
    sudo apt-get install -y mosquitto-clients
fi

echo "Subscribing to ESP32 topic for 10 seconds..."
echo "Press Ctrl+C to stop"
echo ""

timeout 10 mosquitto_sub -h localhost -t "esp32/sensors/dht11" -v || echo "Waiting for messages..."
