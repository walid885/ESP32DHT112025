#!/bin/bash
echo "Starting single ESP32 device simulator (normal mode)..."
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --device esp32_001 \
    --interval 5 \
    --mode normal
