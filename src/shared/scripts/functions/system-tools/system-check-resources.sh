system_check_resources() {
    echo -e "${YELLOW}📊 Kiểm tra tài nguyên hệ thống...${NC}"
    
    # Thu thập thông tin tài nguyên
    cpu_memory_usage=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | sed '1d')
    memory_usage=$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')
    disk_usage=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
    uptime_info=$(uptime -p 2>/dev/null)
    
    # Kiểm tra hệ điều hành để lấy thông tin đúng cách
    os_type=$(uname)
    if [[ "$os_type" == "Darwin" ]]; then
        memory_usage=$(vm_stat | awk -F':' '{gsub(" ", ""); print $2}' | sed -n '2p')
        disk_usage=$(df -h / | awk 'NR==2{print $3"/"$2}')
        uptime_info=$(uptime | awk -F', ' '{print $1}' | sed 's/^.*up //')
    fi

    # Hiển thị thông tin tài nguyên
    echo -e "🔹 ${BOLD}CPU% SỬ DỤNG & RAM CONTAINER:${NC}"
    echo -e "$cpu_memory_usage"
    echo -e "💾 ${BOLD}RAM Tổng:${NC} $memory_usage"
    echo -e "🗄️  ${BOLD}Ổ đĩa Sử dụng:${NC} $disk_usage"
    echo -e "⏳ ${BOLD}Uptime:${NC} $uptime_info"
    
    echo ""
    echo -e "${YELLOW}🔚 Nhấn Enter để quay lại menu...${NC}"
    read -r
}
