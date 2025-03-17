#!/bin/bash

# Kiểm tra xem container nginx-proxy có đang chạy không
if [ "$(docker ps -q -f name=nginx-proxy)" ]; then
    echo -e "\033[1;33m🔄 Đang khởi động lại NGINX Proxy...\033[0m"
    docker restart nginx-proxy
    echo -e "\033[1;32m✅ NGINX Proxy đã khởi động lại thành công!\033[0m"
else
    echo -e "\033[1;31m⚠️ NGINX Proxy không chạy! Khởi động nó trước bằng setup.sh\033[0m"
fi
