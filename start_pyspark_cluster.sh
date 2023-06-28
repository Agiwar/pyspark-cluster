#!/bin/bash
# Create network
docker network create spark_network

# Run Docker Compose files
docker-compose -f docker-compose.master-worker.yaml up -d
docker-compose -f docker-compose.worker.yaml up -d
