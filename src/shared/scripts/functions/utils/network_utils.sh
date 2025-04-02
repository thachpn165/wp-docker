#!/bin/bash

# Check if a port is in use
is_port_in_use() {
    local port="$1"
    netstat -tuln | grep -q ":$port "
}

# Check Internet connection
is_internet_connected() {
    ping -c 1 8.8.8.8 &> /dev/null
}

# Check if a domain is resolvable
is_domain_resolvable() {
    local domain="$1"
    if command -v timeout &>/dev/null; then
    timeout 3 nslookup "$domain" &> /dev/null
    else
    nslookup "$domain" | grep -q "Name:"
    fi
}

# Function to check if a Docker network exists
is_network_exists() {
    local network_name="$1"
    if docker network ls --format '{{.Name}}' | grep -q "^${network_name}$"; then
        return 0  # Network exists
    else
        return 1  # Network does not exist
    fi
}

# Set up Docker network
create_docker_network() {
    local network_name="$1"
    if ! docker network ls | grep -q "$network_name"; then
        echo -e "${YELLOW}🔧 Creating network $network_name...${NC}"
        docker network create "$network_name"
        echo -e "${GREEN}${CHECKMARK} Network $network_name has been created.${NC}"
    else
        echo -e "${GREEN}${CHECKMARK} Network $network_name already exists.${NC}"
    fi
}

