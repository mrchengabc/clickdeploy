#!/bin/bash
# modules/change_ssh_port.sh

echo "=========================================="
echo "  [3/3] Mengubah Port SSH ke 2222...     "
echo "=========================================="

# 1. Pastikan port 2222 sudah dibuka di UFW (langkah antisipasi)
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 2222/tcp
    sudo ufw reload
fi

# 2. Backup file konfigurasi SSH
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 3. Ganti pengaturan port di sshd_config
if grep -q "^#Port 22" /etc/ssh/sshd_config; then
    sudo sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
elif grep -q "^Port " /etc/ssh/sshd_config; then
    sudo sed -i 's/^Port .*/Port 2222/' /etc/ssh/sshd_config
else
    echo "Port 2222" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

# 4. Penanganan khusus Debian 12 (Systemd SSH Socket Activation)
# Jika sistem menggunakan socket activation, ubah port di socket systemd juga
if systemctl is-active --quiet ssh.socket; then
    echo "Mendeteksi Systemd SSH Socket (Debian 12). Menyesuaikan konfigurasi socket..."
    sudo mkdir -p /etc/systemd/system/ssh.socket.d/
    echo -e "[Socket]\nListenStream=\nListenStream=2222" | sudo tee /etc/systemd/system/ssh.socket.d/port.conf > /dev/null
    
    sudo systemctl daemon-reload
    sudo systemctl restart ssh.socket
else
    # Jika menggunakan service SSH standar
    sudo systemctl restart ssh
fi

echo "✔ Port SSH berhasil diubah ke 2222."
echo "⚠️  PENTING: Jangan tutup terminal Anda sekarang!"
echo "Silakan buka terminal baru di komputer Anda dan tes koneksi menggunakan:"
echo "   ssh -p 2222 root@IP_VPS_ANDA"