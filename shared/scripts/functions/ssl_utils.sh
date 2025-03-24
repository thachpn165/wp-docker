#!/bin/bash

# Tạo chứng chỉ SSL tự ký
generate_ssl_cert() {
    local domain="$1"
    local ssl_dir="$2"

    mkdir -p "$ssl_dir"
    echo "🔒 Đang tạo chứng chỉ SSL tự ký cho $domain..."

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$ssl_dir/$domain.key" \
        -out "$ssl_dir/$domain.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"

    echo "✅ Chứng chỉ SSL đã được tạo tại $ssl_dir"
}