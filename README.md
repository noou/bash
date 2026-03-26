# Scrcpy Auto-Connect (Samsung S22) 📱⚡

[![Platform](https://img.shields.io/badge/OS-Linux-orange.svg)](https://manjaro.org/)
[![Tool](https://img.shields.io/badge/Tool-Scrcpy-blue.svg)](https://github.com/Genymobile/scrcpy)

**Проблема:** Разрыв сессии `scrcpy` при разблокировке экрана (сбой энкодера) и динамические IP-адреса.

**Решение:** Отказоустойчивый Bash-скрипт с логикой авторестарта и поиском устройства в подсети.

### 🛠 Ключевые фичи:
- **Resilience:** Отличает закрытие окна от сбоя сети.
- **Auto-Discovery:** Ищет телефон через `nmap`, если сменился IP.
- **Samsung Optimized:** Битрейт 8M, кодек H.264, `--stay-awake`.
- **Power Save:** Гасит экран телефона при закрытии окна на ПК.

### 🚀 Быстрый старт:
1. `adb tcpip 5555` (через кабель один раз).
2. `./s22_wifi.sh`