Cara menjalankan di vps :

# 1. Update sistem dan pastikan Git terinstal di VPS baru Anda
apt update && apt install git -y

# 2. Clone repositori ClickDeploy Anda
git clone https://github.com/mrchengabc/clickdeploy.git

# 3. Masuk ke folder repositori
cd clickdeploy

# 4. Berikan izin eksekusi awal pada file setup utama, lalu jalankan
chmod +x setup.sh
# 5. Terus install Vps
./setup.sh
