#!/bin/bash
# modules/performance_tuning.sh

echo "=========================================="
echo "  [Module] Optimasi Performa (Redis, OPcache, Gzip, Cache)..."
echo "=========================================="

# 1. Install Redis & modul PHP Redis
sudo apt update -y
sudo apt install redis-server php-redis -y
sudo systemctl enable redis-server
sudo systemctl restart redis-server

# 2. Konfigurasi OPcache di php.ini (Debian 12 default PHP 8.2)
PHP_INI="/etc/php/8.2/fpm/php.ini"
if [ -f "$PHP_INI" ]; then
    sudo sed -i 's/^;opcache.enable=1/opcache.enable=1/' "$PHP_INI"
    sudo sed -i 's/^;opcache.memory_consumption=128/opcache.memory_consumption=128/' "$PHP_INI"
    sudo sed -i 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/' "$PHP_INI"
    sudo sed -i 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=2/' "$PHP_INI"
    sudo systemctl restart php8.2-fpm
    echo "✔ OPcache diaktifkan di PHP 8.2."
fi

# 3. Konfigurasi Gzip di Nginx
cat << 'EOF' | sudo tee /etc/nginx/conf.d/gzip.conf > /dev/null
gzip on;
gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;
EOF

# 4. Setup FastCGI Cache global
cat << 'EOF' | sudo tee /etc/nginx/conf.d/fastcgi-cache.conf > /dev/null
fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
EOF

sudo mkdir -p /var/run/nginx-cache
sudo chown -R www-data:www-data /var/run/nginx-cache

sudo systemctl reload nginx
echo "✔ Konfigurasi performa & caching selesai."