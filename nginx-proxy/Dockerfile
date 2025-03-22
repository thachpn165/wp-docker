FROM nginx:latest

# Cài các gói cần thiết
RUN apt update && apt install -y \
    git curl build-essential cmake \
    libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev \
    libxml2 libxml2-dev libyajl-dev \
    pkg-config libtool automake autoconf \
    libpcre2-dev \
    libgeoip-dev doxygen

# ---------- Build Brotli ----------
RUN git clone --depth=1 https://github.com/google/ngx_brotli.git /usr/local/src/ngx_brotli && \
    cd /usr/local/src/ngx_brotli && git submodule update --init

RUN cd /usr/local/src/ngx_brotli/deps/brotli && mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && make install

# ---------- Build ModSecurity ----------
# 1. Build libmodsecurity
RUN git clone --depth=1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity /usr/local/src/ModSecurity && \
    cd /usr/local/src/ModSecurity && \
    git submodule init && git submodule update && \
    ./build.sh && ./configure && make -j$(nproc) && make install

# 2. Build module ngx_http_modsecurity_module
RUN git clone --depth=1 https://github.com/SpiderLabs/ModSecurity-nginx.git /usr/local/src/ModSecurity-nginx

# ---------- Build NGINX với Brotli + ModSecurity module ----------
RUN curl -fsSL http://nginx.org/download/nginx-$(nginx -v 2>&1 | awk -F'/' '{print $2}').tar.gz | tar xz -C /usr/local/src && \
    cd /usr/local/src/nginx-* && \
    ./configure \
        --with-compat \
        --add-dynamic-module=/usr/local/src/ngx_brotli \
        --add-dynamic-module=/usr/local/src/ModSecurity-nginx && \
    make -j$(nproc) modules && \
    cp objs/*.so /etc/nginx/modules/

# ---------- Load các module vào nginx.conf ----------
RUN sed -i '1i load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;' /etc/nginx/nginx.conf && \
    sed -i '2i load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf && \
    sed -i '3i load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;' /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
