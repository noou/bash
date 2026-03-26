#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
PORT="5555"
MODEL_NAME="SM-S901N" # Модель вашего S22 из прошлого скриншота
SUBNET="192.168.31.0/24" # Ваша подсеть

find_phone_ip() {
    echo "[...] Ищу S22 в сети $SUBNET..."
    # Ищем устройства с открытым портом 5555
    local found_ip=$(nmap -p $PORT --open -n $SUBNET | grep "Nmap scan report for" | awk '{print $NF}')
    
    if [ -z "$found_ip" ]; then
        return 1
    fi
    echo "$found_ip"
}

while true; do
    # 1. Поиск или проверка IP
    CURRENT_IP=$(find_phone_ip)

    if [ -z "$CURRENT_IP" ]; then
        echo "[!] Телефон не найден. Проверьте Wi-Fi и 'Отладку'. Повтор через 10с..."
        sleep 10
        continue
    fi

    echo "[✓] Телефон найден: $CURRENT_IP"
    adb connect "$CURRENT_IP:$PORT" > /dev/null

    # 2. Запуск трансляции
    scrcpy --tcpip="$CURRENT_IP:$PORT" \
           --video-bit-rate=8M \
           --stay-awake \
           --power-off-on-close \
           --window-title "Samsung S22 ($CURRENT_IP)"

    # 3. Логика выхода (из прошлого ТЗ)
    if adb -s "$CURRENT_IP:$PORT" shell getprop sys.boot_completed > /dev/null 2>&1; then
        echo "[DONE] Сессия завершена пользователем."
        exit 0
    else
        echo "[RETRY] Связь потеряна. Ищу устройство заново..."
        sleep 2
    fi
done