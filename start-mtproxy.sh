#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CONTAINER_NAME='mtproto-proxy'
PORT='443'
FAKE_DOMAIN='ya.ru'
CONFIG_DIR='/opt/mtg'

echo '🚀 Запуск MTProto прокси с Fake TLS (mtg v2)'
echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
echo -e "📌 Используем домен: ${BLUE}${FAKE_DOMAIN}${NC}"

# Проверяем, свободен ли порт 443
echo -n "🔍 Проверка порта ${PORT}... "
if ss -tuln | grep -q ":${PORT} "; then
    echo -e "${YELLOW}порт занят${NC}"
    for alt_port in 8443 8444 8445; do
        if ! ss -tuln | grep -q ":${alt_port} "; then
            PORT=$alt_port
            echo "   Используем порт: ${PORT}"
            break
        fi
    done
else
    echo -e "${GREEN}свободен${NC}"
fi

# Останавливаем старый контейнер
echo -n '🛑 Остановка старого контейнера... '
sudo docker stop ${CONTAINER_NAME} >/dev/null 2>&1
sudo docker rm ${CONTAINER_NAME} >/dev/null 2>&1
echo -e "${GREEN}готово${NC}"

# Генерируем секрет через mtg
echo -n '🔑 Генерация Fake TLS секрета... '
SECRET=$(sudo docker run --rm nineseconds/mtg:2 generate-secret --hex ${FAKE_DOMAIN})
echo -e "${YELLOW}${SECRET}${NC}"

# Создаём конфиг
mkdir -p ${CONFIG_DIR}
cat > ${CONFIG_DIR}/config.toml << EOF
secret = '${SECRET}'
bind-to = '0.0.0.0:3128'
EOF

# Запускаем mtg v2
echo -n '📦 Запуск контейнера... '
sudo docker run -d \
  --name ${CONTAINER_NAME} \
  --restart unless-stopped \
  -p ${PORT}:3128 \
  -v ${CONFIG_DIR}/config.toml:/config.toml \
  nineseconds/mtg:2 run /config.toml > /dev/null 2>&1

sleep 3
if sudo docker ps | grep -q ${CONTAINER_NAME}; then
    SERVER_IP=$(curl -s ifconfig.me)
    echo -e "${GREEN}✅ УСПЕШНО${NC}"
    echo ''
    echo '📊 ИНФОРМАЦИЯ ДЛЯ ПОДКЛЮЧЕНИЯ:'
    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    echo "🌐 Сервер: ${SERVER_IP}"
    echo "🔌 Порт: ${PORT}"
    echo "🔑 Секрет: ${SECRET}"
    echo "🌐 Fake TLS домен: ${FAKE_DOMAIN}"
    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    echo '🔗 Ссылка для Telegram:'
    echo -e "${GREEN}tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}${NC}"
    echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    cat > ~/mtproto_config.txt << CFGEOF
SERVER=${SERVER_IP}
PORT=${PORT}
SECRET=${SECRET}
DOMAIN=${FAKE_DOMAIN}
LINK=tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${SECRET}
CFGEOF
    echo '✅ Конфигурация сохранена в ~/mtproto_config.txt'
else
    echo -e "${RED}❌ ОШИБКА${NC}"
    sudo docker logs ${CONTAINER_NAME}
fi
