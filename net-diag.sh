#!/usr/bin/env bash
# ============================================================
# Универсальная диагностика доступности домена + TCP-дамп
#
# Использование:
#   sudo bash /root/net-diag.sh <домен>
#   sudo bash /root/net-diag.sh <домен> -p 443,80,22
#   sudo bash /root/net-diag.sh <домен> -p 443 -d 60
#
# Опции:
#   -p ПОРТЫ    через запятую (по умолчанию: 443,80,22)
#   -d СЕКУНДЫ  длительность захвата tcpdump (по умолчанию: 30)
#   -h          справка
# ============================================================

set -u

# --- параметры по умолчанию ---
DEFAULT_PORTS="443,80,22"
DEFAULT_DURATION=30

PORTS="$DEFAULT_PORTS"
DURATION="$DEFAULT_DURATION"
DOMAIN=""

usage() {
    cat <<EOF
Использование: sudo bash $0 <домен> [-p ПОРТЫ] [-d СЕКУНДЫ]

Опции:
  -p ПОРТЫ    список портов через запятую (по умолчанию: $DEFAULT_PORTS)
  -d СЕКУНДЫ  длительность захвата tcpdump (по умолчанию: $DEFAULT_DURATION)
  -h          показать справку

Примеры:
  sudo bash $0 github.com
  sudo bash $0 docker.io -p 443
  sudo bash $0 my-server.com -p 443,8080,2222 -d 60
EOF
    exit 0
}

# --- парсинг аргументов ---
while [ $# -gt 0 ]; do
    case "$1" in
        -p) PORTS="$2"; shift 2 ;;
        -d) DURATION="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) echo "Неизвестная опция: $1"; usage ;;
        *)  if [ -z "$DOMAIN" ]; then DOMAIN="$1"; else
                echo "[!] Только один домен за запуск. Получено лишнее: $1"; exit 1
            fi
            shift ;;
    esac
done

if [ -z "$DOMAIN" ]; then
    echo "[!] Не указан домен"
    usage
fi

# --- права root для tcpdump ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] Скрипт требует прав root (нужен tcpdump). Запустите через sudo."
    exit 1
fi

# --- проверка/установка утилит ---
NEED_INSTALL=""
for tool in tcpdump curl dig nc traceroute; do
    command -v "$tool" >/dev/null 2>&1 || NEED_INSTALL="$NEED_INSTALL $tool"
done
if [ -n "$NEED_INSTALL" ]; then
    echo "[*] Устанавливаю недостающие утилиты:$NEED_INSTALL"
    apt-get update >/dev/null 2>&1
    apt-get install -y dnsutils netcat-openbsd traceroute tcpdump curl >/dev/null 2>&1
fi

# --- подготовка путей ---
TS=$(date +%Y%m%d-%H%M%S)
SAFE_DOMAIN=$(echo "$DOMAIN" | tr '/' '_' | tr ':' '_')
WORK=/tmp/diag-${SAFE_DOMAIN}-${TS}
mkdir -p "$WORK"

REPORT="$WORK/report.txt"
PCAP="$WORK/dump.pcap"
CURL_LOG="$WORK/curl.log"

echo "=========================================="
echo "ДИАГНОСТИКА: $DOMAIN"
echo "Порты: $PORTS"
echo "Длительность дампа: $DURATION сек"
echo "Папка: $WORK"
echo "=========================================="

# --- текстовый отчёт ---
{
echo "=========================================="
echo "ОТЧЁТ ПО ДОСТУПНОСТИ"
echo "Домен: $DOMAIN"
echo "Порты: $PORTS"
echo "Дата:  $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "=========================================="

echo ""
echo "--- Сервер ---"
hostnamectl 2>/dev/null | head -5
echo ""
echo "Внешний IP сервера:"
curl -fsSL --max-time 10 https://ifconfig.me 2>/dev/null; echo
echo ""
echo "Интерфейсы:"
ip -4 a | grep inet
echo ""
echo "Маршрут по умолчанию:"
ip route | head -3

echo ""
echo "=========================================="
echo "DNS"
echo "=========================================="
echo "resolv.conf:"
grep -v '^#' /etc/resolv.conf 2>/dev/null
echo ""
echo "$DOMAIN через системный DNS:"
dig +short "$DOMAIN" 2>&1
echo ""
echo "$DOMAIN через 1.1.1.1:"
dig +short "$DOMAIN" @1.1.1.1 2>&1
echo ""
echo "$DOMAIN через 8.8.8.8:"
dig +short "$DOMAIN" @8.8.8.8 2>&1

echo ""
echo "=========================================="
echo "TCP-ДОСТУПНОСТЬ ($DOMAIN)"
echo "=========================================="
IFS=',' read -r -a PORT_ARR <<< "$PORTS"
for port in "${PORT_ARR[@]}"; do
    port=$(echo "$port" | tr -d ' ')
    echo "$DOMAIN:$port →"
    nc -zv -w 5 "$DOMAIN" "$port" 2>&1
done

echo ""
echo "=========================================="
echo "КОНТРОЛЬНЫЕ ХОСТЫ (для сравнения)"
echo "=========================================="
echo "google.com:443 →"
nc -zv -w 5 google.com 443 2>&1
echo "1.1.1.1:443 →"
nc -zv -w 5 1.1.1.1 443 2>&1

echo ""
echo "=========================================="
echo "TRACEROUTE до $DOMAIN"
echo "=========================================="
traceroute -n -m 20 -w 2 "$DOMAIN" 2>&1

} > "$REPORT" 2>&1

# --- запуск tcpdump ---
echo ""
echo "[1/2] tcpdump на $DURATION сек..."

# собираем IP
IPS=$(dig +short "$DOMAIN" @1.1.1.1 2>/dev/null | grep -E '^[0-9.]+$' | tr '\n' ' ')
if [ -z "$IPS" ]; then
    IPS=$(dig +short "$DOMAIN" 2>/dev/null | grep -E '^[0-9.]+$' | tr '\n' ' ')
fi

# собираем фильтр: порты + IP (если есть)
PORT_FILTER=""
for port in "${PORT_ARR[@]}"; do
    port=$(echo "$port" | tr -d ' ')
    [ -z "$PORT_FILTER" ] && PORT_FILTER="port $port" || PORT_FILTER="$PORT_FILTER or port $port"
done

if [ -n "$IPS" ]; then
    HOST_FILTER=""
    for ip in $IPS; do
        [ -z "$HOST_FILTER" ] && HOST_FILTER="host $ip" || HOST_FILTER="$HOST_FILTER or host $ip"
    done
    FILTER="($PORT_FILTER) and ($HOST_FILTER)"
else
    FILTER="$PORT_FILTER"
    echo "    [!] DNS не отдал IP, использую только фильтр по портам"
fi

echo "    Фильтр: $FILTER"

timeout "$DURATION" tcpdump -i any -nn -s 0 -w "$PCAP" "$FILTER" 2>/dev/null &
TCP_PID=$!
sleep 2

# --- провоцируем трафик ---
echo "[2/2] Тестовые запросы для генерации трафика..."

{
echo "=========================================="
echo "ПОПЫТКИ ПОДКЛЮЧЕНИЯ: $DOMAIN"
echo "Время: $(date -u '+%H:%M:%S UTC')"
echo "=========================================="

for port in "${PORT_ARR[@]}"; do
    port=$(echo "$port" | tr -d ' ')
    echo ""
    echo "--- nc $DOMAIN:$port ---"
    nc -zv -w 8 "$DOMAIN" "$port" 2>&1
done

echo ""
echo "--- curl -v https://$DOMAIN (если 443 в списке) ---"
case ",$PORTS," in
    *,443,*) curl -v --max-time 20 "https://$DOMAIN" 2>&1 ;;
    *)       echo "(порт 443 не в списке, curl пропущен)" ;;
esac

echo ""
echo "--- curl -v http://$DOMAIN (если 80 в списке) ---"
case ",$PORTS," in
    *,80,*) curl -v --max-time 20 "http://$DOMAIN" 2>&1 ;;
    *)      echo "(порт 80 не в списке, curl пропущен)" ;;
esac

} > "$CURL_LOG" 2>&1

wait $TCP_PID 2>/dev/null

# --- финал ---
echo ""
echo "Собираю архив..."

cd /tmp
ARCHIVE="diag-${SAFE_DOMAIN}-${TS}.tar.gz"
tar -czf "$ARCHIVE" "$(basename "$WORK")/"
SIZE=$(du -h "$ARCHIVE" | cut -f1)
PCAP_SIZE=$(du -h "$PCAP" 2>/dev/null | cut -f1)

# сначала краткий отчёт
echo ""
echo "Краткий отчёт:"
echo ""
cat "$REPORT"

# финальный блок — в самом конце
echo ""
echo "=========================================="
echo "✓ ДИАГНОСТИКА ЗАВЕРШЕНА"
echo "=========================================="
echo ""
echo "Все файлы сохранены в:"
echo "  $WORK/"
echo ""
echo "  ├─ report.txt   текстовый отчёт"
echo "  ├─ curl.log     лог curl/nc"
echo "  └─ dump.pcap    TCP-дамп ($PCAP_SIZE)"
echo ""
echo "Архив для отправки саппорту:"
echo "  /tmp/$ARCHIVE"
echo "  Размер: $SIZE"
echo ""
echo "Быстрые команды:"
echo "  cat $REPORT                          # посмотреть отчёт"
echo "  sudo tcpdump -r $PCAP -nn | head     # просмотр дампа"
echo "  ls -lh /tmp/$ARCHIVE                 # проверить архив"
echo "=========================================="
