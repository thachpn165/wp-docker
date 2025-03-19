FROM nginx:latest

# Cài đặt công cụ cần thiết
RUN apt update && apt install -y git curl build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev cmake

# Clone và cập nhật submodule Brotli
RUN git clone --depth=1 https://github.com/google/ngx_brotli.git /usr/local/src/ngx_brotli && \
    cd /usr/local/src/ngx_brotli && git submodule update --init

# Build Brotli
RUN cd /usr/local/src/ngx_brotli/deps/brotli && mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install

# Build NGINX với Brotli
RUN curl -fsSL http://nginx.org/download/nginx-$(nginx -v 2>&1 | awk -F'/' '{print $2}').tar.gz | tar xz -C /usr/local/src && \
    cd /usr/local/src/nginx-* && \
    ./configure --with-compat --add-dynamic-module=/usr/local/src/ngx_brotli && \
    make -j$(nproc) modules && \
    cp objs/ngx_http_brotli_filter_module.so /etc/nginx/modules/ && \
    cp objs/ngx_http_brotli_static_module.so /etc/nginx/modules/

# Chỉnh sửa nginx.conf để đảm bảo load module đúng vị trí
RUN sed -i '1i load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;' /etc/nginx/nginx.conf && \
    sed -i '2i load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
