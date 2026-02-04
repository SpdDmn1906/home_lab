#!/bin/bash
# Docker Container Health Check Script
# Checks the health of all Docker containers

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_container_health() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "not found")
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no-healthcheck")
    local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo "0")

    echo -n "$container: "

    if [ "$status" == "not found" ]; then
        echo -e "${RED}Container not found${NC}"
        return 1
    elif [ "$status" != "running" ]; then
        echo -e "${RED}Status: $status${NC}"
        return 1
    else
        if [ "$health" == "healthy" ]; then
            echo -e "${GREEN}Running (Healthy)${NC}"
        elif [ "$health" == "no-healthcheck" ]; then
            echo -e "${GREEN}Running${NC}"
        elif [ "$health" == "unhealthy" ]; then
            echo -e "${RED}Running (Unhealthy)${NC}"
            return 1
        else
            echo -e "${YELLOW}Running (Health: $health)${NC}"
        fi

        if [ "$restart_count" -gt 10 ]; then
            echo -e "  ${YELLOW}WARNING: Restarted $restart_count times${NC}"
        fi
    fi

    return 0
}

check_container_resources() {
    local container=$1
    echo -e "\n${YELLOW}Resource Usage for $container:${NC}"
    docker stats --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" "$container" 2>/dev/null || echo "Unable to get stats"
}

main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Docker Container Health Check${NC}"
    echo -e "${GREEN}========================================\n${NC}"

    local errors=0
    local containers

    # Get list of containers from docker-compose if available
    if [ -f "docker/docker-compose.yml" ]; then
        cd docker 2>/dev/null || true
        containers=$(docker-compose ps --services 2>/dev/null || docker ps --format "{{.Names}}")
    else
        containers=$(docker ps --format "{{.Names}}")
    fi

    if [ -z "$containers" ]; then
        echo -e "${RED}No containers found${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Checking container status...${NC}\n"
    for container in $containers; do
        if ! check_container_health "$container"; then
            ((errors++))
        fi
    done

    echo -e "\n${YELLOW}Resource Usage Summary:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

    echo -e "\n${GREEN}========================================${NC}"
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}All containers are healthy${NC}"
        exit 0
    else
        echo -e "${RED}Found $errors unhealthy container(s)${NC}"
        exit 1
    fi
}

main "$@"



