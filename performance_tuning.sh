#!/bin/bash
# modules/performance_tuning.sh

echo "=========================================="
echo "  [Module] Optimasi Performa Global VPS   "
echo "=========================================="

# 1. DETEKSI TOTAL RAM VPS & TENTUKAN BATAS AMAN
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
echo "✔ Mendeteksi Total RAM VPS: ${TOTAL_RAM_MB}MB"

if [ "$TOTAL_RAM_MB" -lt 1500 ]; then
    # VPS RAM 1GB atau kurang
    MAX_CHILDREN=6
    INNODB_BUFFER="128M"
    QUERY_CACHE="16M"
    echo "✔ Menerapkan profil: RAM Kecil (< 1.5GB)"
elif [ "$TOTAL_RAM_MB" -lt 3500 ]; then
    # VPS RAM 2GB - 3GB
    MAX_CHILDREN=15
    INNODB_BUFFER="384M"
    QUERY_CACHE="32M"
    echo "✔ Menerapkan profil: RAM Sedang (2GB - 3GB)"
else
    # VPS RAM 4GB ke atas
    MAX_CHILDREN=30
    INNODB_BUFFER="1G"
    QUERY_CACHE="64M"
    echo "✔ Menerapkan profil: RAM Besar (>= 4GB)"
fi

# 2. INSTALASI & AKTIFKAN REDIS
echo "Mengonfigurasi Redis Server..."
sudo apt update -y
sudo apt install redis-server php-redis -y
sudo systemctl enable redis-server
sudo systemctl restart redis-server
echo "✔ Redis Server aktif."

# 3. DETEKSI VERSI PHP, AKTIFKAN OPCACHE & TUNING PHP-FPM
PHP_FPM_CONF=""
PHP_INI=""
PHP_SERVICE=""
for v in 8.3 8.2 8.1 8.0 7.4; do
    if [ -f "/etc/php/$v/fpm/pool.d/www.conf" ]; then
        PHP_FPM_CONF="/etc/php/$v/fpm/pool.d/www.conf"
        PHP_INI="/etc/php/$v/fpm/php.ini"
        PHP_SERVICE="php$v-fpm"
        break
    fi
done

# Aktifkan OPcache di php.ini
if [ -f "$PHP_INI" ]; then
    sudo sed -i 's/^;opcache.enable=1/opcache.enable=1/' "$PHP_INI"
    sudo sed -i 's/^;opcache.memory_consumption=128/opcache.memory_consumption=128/' "$PHP_INI"
    sudo sed -i 's/^;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=10000/' "$PHP_INI"
    sudo sed -i 's/^;opcache.revalidate_freq=2/opcache.revalidate_freq=2/' "$PHP_INI"
    echo "✔ OPcache diaktifkan di php.ini."
fi

# Terapkan batas aman proses PHP-FPM (Ondemand)
if [ -f "$PHP_FPM_CONF" ]; then
    echo "Mengonfigurasi batas aman proses PHP-FPM..."
    sudo sed -i 's/^pm =.*/pm = ondemand/' "$PHP_FPM_CONF"
    sudo sed -i "s/^pm.max_children =.*/pm.max_children = $MAX_CHILDREN/" "$PHP_FPM_CONF"
    sudo sed -i 's/^;pm.process_idle_timeout =.*/pm.process_idle_timeout = 10s/' "$PHP_FPM_CONF"
    sudo sed -i 's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 10s/' "$PHP_FPM_CONF"
    sudo sed -i 's/^;pm.max_requests =.*/pm.max_requests = 500/' "$PHP_FPM_CONF"
    sudo sed -i 's/^pm.max_requests =.*/pm.max_requests = 500/' "$PHP_FPM_CONF"
    
    sudo systemctl restart "$PHP_SERVICE"
    echo "✔ PHP-FPM dioptimalkan dan di-restart."
fi

# 4. TUNING DATABASE (MariaDB)
DB_CONF=""
if [ -f "/etc/mysql/mariadb.conf.d/50-server.cnf" ]; then
    DB_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
elif [ -f "/etc/mysql/my.cnf" ]; then
    DB_CONF="/etc/mysql/my.cnf"
fi

if [ ! -z "$DB_CONF" ]; then
    echo "Mengonfigurasi alokasi RAM database..."
    sudo sed -i "s/^innodb_buffer_pool_size.*/innodb_buffer_pool_size = $INNODB_BUFFER/g" "$DB_CONF"
    sudo sed -i "s/^query_cache_size.*/query_cache_size = $QUERY_CACHE/g" "$DB_CONF"
    
    if ! grep -q "innodb_buffer_pool_size" "$DB_CONF"; then
        sudo sed -i "/\[mysqld\]/a innodb_buffer_pool_size = $INNODB_BUFFER" "$DB_CONF"
    fi
    if ! grep -q "query_cache_size" "$DB_CONF"; then
        sudo sed -i "/\[mysqld\]/a query_cache_size = $QUERY_CACHE" "$DB_CONF"
    fi
    
    sudo systemctl restart mariadb
    echo "✔ MariaDB dioptimalkan dan di-restart."
fi

# 5. AKTIFKAN GZIP COMPRESSION DI NGINX
echo "Mengonfigurasi Gzip Compression..."
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
echo "✔ Gzip Compression aktif."

# 6. SETUP FASTCGI CACHE GLOBAL DI NGINX
echo "Mengonfigurasi FastCGI Cache global..."
cat << 'EOF' | sudo tee /etc/nginx/conf.d/fastcgi-cache.conf > /dev/null
fastcgi_cache_path /var/run/nginx-cache levels=1:2 keys_zone=WORDPRESS:100m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";
fastcgi_cache_use_stale error timeout invalid_header http_500;
EOF

sudo mkdir -p /var/run/nginx-cache
sudo chown -R www-data:www-data /var/run/nginx-cache
echo "✔ FastCGI Cache global siap."

# 7. PINDAI & NONAKTIFKAN WP-CRON DI SEMUA WORDPRESS
echo "Memindai direktori /var/www/ untuk optimasi WP-Cron..."
WP_CONFIG_FILES=$(find /var/www -name "wp-config.php" 2>/dev/null)

if [ -z "$WP_CONFIG_FILES" ]; then
    echo "✔ Tidak ada WordPress yang ditemukan."
else
    for wp_conf in $WP_CONFIG_FILES; do
        if ! grep -q "DISABLE_WP_CRON" "$wp_conf"; then
            sudo sed -i "/\/\* That's all, stop editing/i define('DISABLE_WP_CRON', true);" "$wp_conf"
            echo "✔ WP-Cron dinonaktifkan di: $wp_conf"
            
            DOMAIN=$(echo "$wp_conf" | awk -F'/' '{print $4}')
            
            # Daftarkan ke Linux Crontab harian setiap 10 menit
            if ! crontab -l 2>/dev/null | grep -q "$DOMAIN/wp-cron.php"; then
                (crontab -l 2>/dev/null; echo "*/10 * * * * wget -q -O - http://$DOMAIN/wp-cron.php?doing_wp_cron >/dev/null 2>&1") | crontab -
                echo "✔ Linux Cron Job aktif untuk http://$DOMAIN"
            fi
        else
            echo "✔ WP-Cron sudah dinonaktifkan sebelumnya di: $wp_conf"
        fi
    done
fi

# Reload Nginx untuk menerapkan perubahan Gzip dan FastCGI Cache
sudo systemctl reload nginx
echo "=========================================="
echo "✔ Optimasi Performa Global & Auto-Tuning Selesai!"
echo "=========================================="