# Установка NaiveProxy на клиент:
1. Скачиваем последний релиз:
```bash
NAIVE_VER=$(curl -sL https://api.github.com/repos/klzgrad/naiveproxy/releases/latest | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p' | head -n 1)
curl -sL https://github.com/klzgrad/naiveproxy/releases/download/${NAIVE_VER}/naiveproxy-${NAIVE_VER}-linux-x64.tar.xz | tar -xJ
cd naiveproxy-${NAIVE_VER}-linux-x64
nano config.json
```

2. Редактируем:
```jsonc
{
  "listen": [
    "socks://127.0.0.1:1080",
    "http://127.0.0.1:8080"
  ], // Можно заменить на друге порты
  // quic:// можно заменить на https:// если нужен HTTP/2
  "proxy": "quic://user:pass@example.com", // Замените user на имя, pass на пароль и example.com на ваш домен (это всё можно найти в Caddyfile на сервере)
  "log": ""
}
```

3. Запускаем:
```bash
./naive
```
Запуск поднимет SOCKS5 прокси на 127.0.0.1:1080 и HTTP на 8080 который можно например, подключить в Telegram и т. д.
