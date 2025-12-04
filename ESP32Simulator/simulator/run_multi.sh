#!/bin/bash
echo "Starting multi-device ESP32 simulator (5 devices)..."
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --interval 5 \
    --multi 5
