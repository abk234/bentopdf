#!/bin/bash

# BentoPDF Stop Script
# This script stops the BentoPDF application using Docker Compose

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping BentoPDF...${NC}"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    exit 1
fi

# Determine which docker compose command to use
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^bentopdf$"; then
    echo -e "${YELLOW}Warning: BentoPDF container is not running.${NC}"
    exit 0
fi

# Stop the services
echo -e "${YELLOW}Stopping Docker Compose services...${NC}"
$COMPOSE_CMD down

# Verify container is stopped
if ! docker ps --format '{{.Names}}' | grep -q "^bentopdf$"; then
    echo -e "${GREEN}✓ BentoPDF stopped successfully!${NC}"
else
    echo -e "${RED}Error: Failed to stop BentoPDF container.${NC}"
    exit 1
fi

