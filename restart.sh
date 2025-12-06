#!/bin/bash

# BentoPDF Restart Script
# This script restarts the BentoPDF application using Docker Compose

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Restarting BentoPDF...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Stop the application
if [ -f "$SCRIPT_DIR/stop.sh" ]; then
    "$SCRIPT_DIR/stop.sh"
else
    echo -e "${YELLOW}Stop script not found, stopping manually...${NC}"
    # Determine which docker compose command to use
    if docker compose version &> /dev/null 2>&1; then
        docker compose down
    else
        docker-compose down
    fi
fi

# Wait a moment
sleep 1

# Start the application
if [ -f "$SCRIPT_DIR/start.sh" ]; then
    "$SCRIPT_DIR/start.sh"
else
    echo -e "${YELLOW}Start script not found, starting manually...${NC}"
    # Determine which docker compose command to use
    if docker compose version &> /dev/null 2>&1; then
        docker compose up -d
    else
        docker-compose up -d
    fi
fi

echo -e "${GREEN}✓ BentoPDF restarted successfully!${NC}"

