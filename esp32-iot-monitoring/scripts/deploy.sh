#!/bin/bash
echo "Starting all services..."
docker-compose up -d
echo "Waiting for services to be ready..."
sleep 15
echo "Services deployed successfully!"
echo ""
echo "Access URLs:"
echo "- Node-RED: http://localhost:1880"
echo "- Grafana: http://localhost:3000 (admin/admin)"
echo "- Kibana: http://localhost:5601"
echo "- Elasticsearch: http://localhost:9200"
echo "- MQTT Broker: mqtt://localhost:1883"
