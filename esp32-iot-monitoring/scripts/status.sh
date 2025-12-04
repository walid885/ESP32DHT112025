#!/bin/bash
echo "Service Status:"
docker-compose ps
echo ""
echo "Elasticsearch Health:"
curl -s http://localhost:9200/_cluster/health?pretty
