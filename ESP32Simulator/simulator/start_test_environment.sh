#!/bin/bash

echo "Starting complete test environment..."

# Start Docker services
cd ..
./scripts/deploy.sh

# Wait for services
echo "Waiting for services to initialize (30s)..."
sleep 30

# Verify services
echo ""
echo "Service Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "✓ Test environment ready!"
echo ""
echo "You can now run the simulator:"
echo "  cd simulator"
echo "  ./run_single.sh"
echo ""
echo "Monitor data:"
echo "  Node-RED: http://localhost:1880"
echo "  Grafana: http://localhost:3000"
echo "  Kibana: http://localhost:5601"
