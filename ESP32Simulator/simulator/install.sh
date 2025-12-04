#!/bin/bash

echo "Installing ESP32 Simulator Dependencies..."

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 is not installed"
    exit 1
fi

echo "Python version: $(python3 --version)"

# Install pip if not present
if ! command -v pip3 &> /dev/null; then
    echo "Installing pip3..."
    sudo apt-get update
    sudo apt-get install -y python3-pip
fi

# Install requirements
echo "Installing Python packages..."
pip3 install -r requirements.txt

echo ""
echo "✓ Installation complete!"
echo ""
echo "Usage examples:"
echo "  ./run_single.sh          - Single device, normal mode"
echo "  ./run_multi.sh           - Multiple devices (5)"
echo "  ./run_single_spike.sh    - Anomaly testing"
echo "  ./run_test.sh            - 60-second test"
echo "  ./run_heating.sh         - Temperature increase simulation"
echo ""
