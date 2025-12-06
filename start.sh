#!/bin/bash

# BentoPDF Startup Script
# This script starts the BentoPDF application using Docker Compose

# Note: We don't use 'set -e' here because we need to handle port checking gracefully

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting BentoPDF...${NC}"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo -e "${RED}Error: Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Determine which docker compose command to use
if docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Function to check if a port is available
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        # Use lsof if available (macOS, Linux)
        # lsof returns 0 if port is in use, so we negate it
        ! lsof -i :$port &> /dev/null
    elif command -v netstat &> /dev/null; then
        # Use netstat as fallback
        # netstat returns 0 if grep finds a match (port in use)
        ! netstat -an 2>/dev/null | grep -q ":$port.*LISTEN"
    elif command -v ss &> /dev/null; then
        # Use ss as another fallback (Linux)
        # ss returns 0 if grep finds a match (port in use)
        ! ss -lnt 2>/dev/null | grep -q ":$port "
    else
        # If no tool is available, try to connect to the port
        if command -v nc &> /dev/null; then
            # nc -z returns 0 if connection succeeds (port is in use)
            # So we want to return the opposite
            ! nc -z localhost $port 2>/dev/null
        else
            # Last resort: assume port is available if we can't check
            true
        fi
    fi
}

# Function to find an available port starting from a given port
find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_port=$((start_port + 100))
    
    while [ $port -le $max_port ]; do
        if check_port $port; then
            echo $port
            return 0
        fi
        port=$((port + 1))
    done
    
    echo ""
    return 1
}

# Get port from environment variable or use default
DEFAULT_PORT=${BENTOPDF_PORT:-8080}
SELECTED_PORT=$DEFAULT_PORT

# Check if the default port is available
if ! check_port $DEFAULT_PORT; then
    echo -e "${YELLOW}Port $DEFAULT_PORT is already in use.${NC}"
    echo -e "${YELLOW}Searching for an available port...${NC}"
    
    AVAILABLE_PORT=$(find_available_port $DEFAULT_PORT)
    
    if [ -z "$AVAILABLE_PORT" ]; then
        echo -e "${RED}Error: Could not find an available port in range $DEFAULT_PORT-$((DEFAULT_PORT + 100)).${NC}"
        echo -e "${RED}Please free up a port or set BENTOPDF_PORT environment variable to a specific port.${NC}"
        exit 1
    fi
    
    SELECTED_PORT=$AVAILABLE_PORT
    export BENTOPDF_PORT=$SELECTED_PORT
    echo -e "${GREEN}Found available port: $SELECTED_PORT${NC}"
else
    # Use the default port or the one from environment
    export BENTOPDF_PORT=$SELECTED_PORT
fi

# Check if container is already running
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^bentopdf$"; then
    echo -e "${YELLOW}Warning: BentoPDF container is already running.${NC}"
    echo -e "${YELLOW}To restart, please run: ./stop.sh first${NC}"
    exit 0
fi

# Start the services
echo -e "${GREEN}Starting Docker Compose services on port $SELECTED_PORT...${NC}"
if ! $COMPOSE_CMD up -d; then
    echo -e "${RED}Error: Failed to start Docker Compose services.${NC}"
    echo "Check logs with: $COMPOSE_CMD logs"
    exit 1
fi

# Wait a moment for the container to start
sleep 2

# Check if container started successfully
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^bentopdf$"; then
    echo -e "${GREEN}✓ BentoPDF started successfully!${NC}"
    echo -e "${GREEN}The application is available at: http://localhost:$SELECTED_PORT${NC}"
    echo ""
    echo "To view logs, run: $COMPOSE_CMD logs -f"
    echo "To stop the application, run: ./stop.sh"
    if [ $SELECTED_PORT -ne $DEFAULT_PORT ]; then
        echo ""
        echo -e "${YELLOW}Note: Using port $SELECTED_PORT instead of default port $DEFAULT_PORT due to port conflict.${NC}"
        echo -e "${YELLOW}To use a specific port, set BENTOPDF_PORT environment variable:${NC}"
        echo -e "${YELLOW}  export BENTOPDF_PORT=8080${NC}"
        echo -e "${YELLOW}  ./start.sh${NC}"
    fi
else
    echo -e "${RED}Error: Failed to start BentoPDF container.${NC}"
    echo "Check logs with: $COMPOSE_CMD logs"
    exit 1
fi

