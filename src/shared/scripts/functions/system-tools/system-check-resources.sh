system_check_resources() {
    echo -e "${YELLOW}📊 Checking system resources...${NC}"
    
    # Collect resource information
    cpu_memory_usage=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | sed '1d')
    memory_usage=$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')
    disk_usage=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
    uptime_info=$(uptime -p 2>/dev/null)
    
    # Check operating system to get correct information
    os_type=$(uname)
    if [[ "$os_type" == "Darwin" ]]; then
        memory_usage=$(vm_stat | awk -F':' '{gsub(" ", ""); print $2}' | sed -n '2p')
        disk_usage=$(df -h / | awk 'NR==2{print $3"/"$2}')
        uptime_info=$(uptime | awk -F', ' '{print $1}' | sed 's/^.*up //')
    fi

    # Display resource information
    echo -e "🔹 ${BOLD}CPU% USAGE & CONTAINER RAM:${NC}"
    echo -e "$cpu_memory_usage"
    echo -e "💾 ${BOLD}Total RAM:${NC} $memory_usage"
    echo -e "🗄️  ${BOLD}Disk Usage:${NC} $disk_usage"
    echo -e "⏳ ${BOLD}Uptime:${NC} $uptime_info"
    
    echo ""
    echo -e "${YELLOW}🔚 Press Enter to return to menu...${NC}"
    read -r
}
