#!/bin/bash
echo "Simulating heating scenario (increasing temperature)..."
python3 esp32_simulator.py \
    --host localhost \
    --port 1883 \
    --device esp32_heating \
    --interval 3 \
    --mode increasing
