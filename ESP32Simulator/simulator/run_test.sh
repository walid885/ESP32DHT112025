#!/bin/bash
echo "Running 60-second test simulation..."
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --device esp32_test \
    --interval 2 \
    --duration 60 \
    --mode random
