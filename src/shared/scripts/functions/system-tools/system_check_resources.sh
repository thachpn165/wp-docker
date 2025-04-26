#!/bin/bash
# ==================================================
# File: system_check_resources.sh
# Description: Displays system and Docker resource usage, including:
#              - Docker container CPU and memory usage
#              - Total system memory usage
#              - Disk usage
#              - System uptime
#              Supports Linux and macOS with custom memory calculation for macOS.
# Functions:
#   - system_logic_check_resources: Display system and Docker resource usage.
#       Parameters: None.
# ==================================================

system_logic_check_resources() {
  local cpu_memory_usage memory_usage disk_usage uptime_info os_type

  # 🐳 Get Docker container resource usage
  cpu_memory_usage=$(docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | sed '1d')

  # 🧠 Default memory and disk usage (Linux)
  memory_usage=$(free -h 2>/dev/null | awk 'NR==2{print $3"/"$2}')
  disk_usage=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2}')
  uptime_info=$(uptime -p 2>/dev/null)

  os_type=$(uname -s)
  debug_log "[SYSTEM] Detected OS: $os_type"

  if [[ "$os_type" == "Darwin" ]]; then
    # 🧠 macOS-specific memory usage
    local page_size
    page_size=$(sysctl -n hw.pagesize)

    local free_pages
    free_pages=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')

    local inactive_pages
    inactive_pages=$(vm_stat | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')

    local speculative_pages
    speculative_pages=$(vm_stat | grep "Pages speculative" | awk '{print $3}' | sed 's/\.//')

    local free_bytes
    free_bytes=$(( (free_pages + inactive_pages + speculative_pages) * page_size ))

    local total_mem
    total_mem=$(sysctl -n hw.memsize)
    memory_usage="$(numfmt --to=iec $((total_mem - free_bytes))) / $(numfmt --to=iec $total_mem)"

    # Get disk usage and uptime on macOS
    disk_usage=$(df -h / | awk 'NR==2{print $3"/"$2}')
    uptime_info=$(uptime | awk -F', ' '{print $1}' | sed 's/^.*up //')
  fi

  # Display system resource summary
  print_msg title "$TITLE_SYSTEM_RESOURCES"
  echo -e "$cpu_memory_usage"
  print_msg label "$(printf "$LABEL_TOTAL_RAM" "$memory_usage")"
  print_msg label "$(printf "$LABEL_DISK_USAGE" "$disk_usage")"
  print_msg label "$(printf "$LABEL_UPTIME" "$uptime_info")"
}