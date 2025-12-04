#!/bin/bash
echo "Starting ESP32 simulator with spike mode (anomaly testing)..."
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --device esp32_test \
    --interval 3 \
    --mode spike
