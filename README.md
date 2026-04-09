Установка Docker (если ещё не установлен)
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io -y

wget https://raw.githubusercontent.com/aleksander4666/mtproxy/refs/heads/main/start-mtproxy.sh
chmod +x start-mtproxy.sh
./start-mtproxy.sh
