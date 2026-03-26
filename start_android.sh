#!/bin/bash

# --- КОНФИГУРАЦИЯ ---
MODEL="SM-S901N"
CACHE_FILE="/tmp/s22_v3.cache"
LOG_FILE="/tmp/scrcpy_s22.log"
# Твой базовый IP для первичной проверки (ускоряет запуск)
DEFAULT_IP="192.168.31.138"

# Очистка при выходе (Ctrl+C)
trap 'echo "[!] Выход..."; adb shell input keyevent 26 >/dev/null 2>&1; exit 0' SIGINT SIGTERM

get_target() {
    # 1. Проверка Кэша
    if [ -f "$CACHE_FILE" ]; then
        local cached=$(cat "$CACHE_FILE")
        if timeout 1.5 adb connect "$cached" | grep -qE "connected|already"; then
            echo "$cached" && return 0
        fi
    fi

    # 2. Быстрый поиск IP в ARP-таблице (без nmap по всей сети)
    local target_ip=$(ip neigh show | grep -i "S22" | awk '{print $1}')
    [ -z "$target_ip" ] && target_ip="$DEFAULT_IP"

    # 3. Поиск активного порта только на целевом IP
    echo "[...] Поиск порта на $target_ip..." >&2
    local port=$(nmap -p 5555,30000-65535 --open "$target_ip" -n -oG - | grep -oP '\d+(?=/open/tcp)' | head -1)

    if [ -n "$port" ]; then
        local pair="$target_ip:$port"
        if adb connect "$pair" | grep -q "connected"; then
            echo "$pair" > "$CACHE_FILE"
            echo "$pair"
            return 0
        fi
    fi
    return 1
}

while true; do
    DEVICE=$(get_target)

    if [ -z "$DEVICE" ]; then
        echo "[!] S22 не найден. Включите 'Отладку по Wi-Fi'. Сон 10с..."
        sleep 10
        continue
    fi

    echo "[✓] Сессия активна: $DEVICE"
    > "$LOG_FILE"

    # Запуск с оптимизацией под Samsung S22
    scrcpy --tcpip="$DEVICE" \
           --video-bit-rate=8M \
           --always-on-top \
           --stay-awake \
           --power-off-on-close \
           --window-title "S22 Resilience" \
           --verbosity=verbose 2> "$LOG_FILE"

    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[DONE] Штатное завершение."
        adb -s "$DEVICE" shell input keyevent 26 >/dev/null 2>&1
        exit 0
    fi

    # Анализ сбоя энкодера (Lock/Unlock)
    if grep -qiE "device disconnected|encoder error|connection reset" "$LOG_FILE"; then
        echo "[RETRY] Сбой One UI энкодера. Переподключение через 3с..."
        sleep 3
    else
        echo "[!] Ошибка (Код: $EXIT_CODE). Проверьте телефон. Жду 10с..."
        sleep 10
    fi
done