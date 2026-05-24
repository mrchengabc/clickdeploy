#!/bin/bash
# modules/secure_vps.sh

echo "=========================================="
echo "  [2/3] Mengaktifkan Keamanan VPS...     "
echo "=========================================="

# Update & install UFW dan Fail2ban
sudo apt update -y
sudo apt install ufw fail2ban -y

# Reset konfigurasi firewall ke default (blokir semua koneksi masuk)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Izinkan port-port penting
echo "Membuka port firewall..."
sudo ufw allow 80/tcp     # HTTP (Nginx)
sudo ufw allow 443/tcp    # HTTPS (Nginx SSL)
sudo ufw allow 22/tcp     # SSH Lama (untuk keamanan sementara sebelum diubah)
sudo ufw allow 2222/tcp   # SSH Baru

# Aktifkan UFW secara otomatis tanpa konfirmasi interaktif
echo "y" | sudo ufw enable

# Konfigurasi & Jalankan Fail2Ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

echo "✔ Firewall UFW telah aktif."
echo "✔ Fail2ban telah aktif untuk mencegah serangan brute-force."