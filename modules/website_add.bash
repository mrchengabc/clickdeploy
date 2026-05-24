#!/bin/bash
# modules/website_add.sh

echo "=========================================="
echo "  [Module] Tambah Domain Baru (Add Domain)"
echo "=========================================="

read -p "Masukkan Nama Domain (misal: domain.com): " domain
if [ -z "$domain" ]; then
    echo "❌ Domain tidak boleh kosong!"
    exit 1
fi

echo "Pilih Tipe Website:"
echo "1) HTML Biasa"
echo "2) PHP Standar"
echo "3) WordPress (Otomatis)"
read -p "Pilihan [1-3]: " type_opt

# Buat direktori publik
WEB_ROOT="/var/www/$domain/public"
sudo mkdir -p "$WEB_ROOT"
sudo chown -R www-data:www-data "/var/www/$domain"

# Generate password random untuk database
DB_NAME=$(echo "$domain" | sed 's/\./_/g')
DB_USER="usr_${DB_NAME:0:10}"
DB_PASS=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')

setup_database() {
    # Pastikan MariaDB terinstal
    if ! command -v mariadb >/dev/null 2>&1; then
        sudo apt update && sudo apt install mariadb-server -y
        sudo mysql_secure_installation
    fi
    # Buat DB & User
    sudo mariadb -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
    sudo mariadb -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mariadb -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
    sudo mariadb -e "FLUSH PRIVILEGES;"
    echo "✔ Database berhasil dibuat:"
    echo "   DB Name: $DB_NAME"
    echo "   DB User: $DB_USER"
    echo "   DB Pass: $DB_PASS"
}

# 1. Unduh file website sesuai pilihan
case $type_opt in
    1)
        echo "<h1>Welcome to $domain</h1>" | sudo tee "$WEB_ROOT/index.html" > /dev/null
        ;;
    2)
        echo "<?php phpinfo(); ?>" | sudo tee "$WEB_ROOT/index.php" > /dev/null
        setup_database
        ;;
    3)
        setup_database
        # Gunakan WP-CLI untuk mengunduh WordPress core
        if ! command -v wp >/dev/null 2>&1; then
            curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
            chmod +x wp-cli.phar
            sudo mv wp-cli.phar /usr/local/bin/wp
        fi
        sudo -u www-data wp core download --path="$WEB_ROOT" --locale=id_ID --allow-root
        sudo -u www-data wp config create --path="$WEB_ROOT" --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --dbhost="localhost" --allow-root
        ;;
    *)
        echo "Pilihan salah."
        exit 1
        ;;
esac

# 2. Buat Nginx Virtual Host Configuration
# Menggunakan php8.2-fpm secara default
VHOST="/etc/nginx/sites-available/$domain"
cat << EOF | sudo tee "$VHOST" > /dev/null
server {
    listen 80;
    server_name $domain www.$domain;
    root $WEB_ROOT;
    index index.php index.html index.htm;

    # Include pengamanan jika file security_hardening.sh sudah dijalankan
    include snippets/security-hardened.conf;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Aktifkan vhost dan reload nginx
sudo ln -sf "$VHOST" "/etc/nginx/sites-enabled/"
sudo chown -R www-data:www-data "/var/www/$domain"
sudo systemctl reload nginx

echo "✔ Website $domain berhasil dibuat!"