#shellcheck disable=SC2034
#shellcheck disable=SC2154
function debug_process() {
    export PS4='\e[36m+(${BASH_SOURCE}:${LINENO}):\e[0m ${FUNCNAME[0]:+\e[35m${FUNCNAME[0]}():\e[0m }'
    set -x
}

###
# Hàm kiểm tra trạng thái load của một số tập tin quan trọng

LOADED_CONFIG_FILE=false
LOADED_UTILS_FUNCTIONS=false
LOADED_PHP_FUNCTIONS=false
LOADED_WEBSITE_FUNCTIONS=false
LOADED_DOCKER_FUNCTIONS=false
LOADED_BACKUP_FUNCTIONS=false
LOADED_RCLONE_FUNCTIONS=false
LOADED_SSL_FUNCTIONS=false