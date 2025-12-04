#!/bin/bash
# Edit BROKER_IP before running
BROKER_IP="192.168.1.100"

echo "Connecting to remote broker at ${BROKER_IP}..."
python3 esp32_simulator.py \
    --host ${BROKER_IP} \
    --port 1883 \
    --device esp32_001 \
    --interval 5 \
    --mode normal
