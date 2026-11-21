## Подготовка
Теперь ставим sing-box:
```bash
curl -fsSL https://sing-box.app/install.sh | sh -s -- --beta
```

Генерируем нужные значения:
```bash
sing-box generate rand --hex 8 # Имя для MASQUE
sing-box generate rand --hex 8 # Пароль для MASQUE
sing-box generate rand --hex 8 # Пароль для Trojan
sing-box generate uuid # UUID для VLESS
sing-box generate reality-keypair # Ключи для VLESS (обязательно сохраните публичный ключ)
sing-box generate rand --hex 2 # Short ID для VLESS
sing-box generate rand --hex 8 # Пароль для AnyTLS
sing-box generate rand --hex 8 # Имя для AnyTLS
sing-box generate rand --hex 8 # Имя для TUIC
sing-box generate uuid # UUID для TUIC
sing-box generate rand --hex 8 # Пароль от TUIC
sing-box generate rand --base64 16 # Пароль для Shadowsocks
sing-box generate rand --hex 8 # Имя для ShadowTLS
sing-box generate rand --hex 8 # Пароль для ShadowTLS
``` 

Открываем все необходимые порты (команда только для ufw):
```bash
sudo ufw limit 22/tcp
sudo ufw allow 443
sudo ufw allow 80/tcp
sudo ufw allow 20808/tcp
sudo ufw allow 10808/tcp
sudo ufw allow 8443/tcp
sudo ufw allow 1080/tcp
sudo ufw allow 8080/udp
sudo ufw allow 1234/udp
sudo ufw allow 500/udp
sudo ufw enable
```

## Редактирование
Редактируем конфиг:
```bash
sudoedit /etc/sing-box/config.json
```

Вставьте (если тут уже что-то было удалите):
```json
{
  "log": {
    "level": "warn"
  },
  "endpoints": [
    {
      "type": "masque-server",
      "tag": "masque-server",
      "listen": "::",
      "listen_port": 500,
      "users": [
        {
          "username": "username",
          "password": "password"
        }
      ],
      "version": 3,
      "tls": {
        "enabled": true,
        "certificate_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.crt",
        "key_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.key"
      },
      "address": "10.0.0.1/24"
    }
  ],
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan-in",
      "listen": "::",
      "listen_port": 20808,
      "users": [
        {
          "password": "password"
        }
      ],
      "tls": {
        "enabled": true,
        "certificate_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.crt",
        "key_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.key"
      },
      "fallback": {
        "server": "127.0.0.1",
        "server_port": 8082
      },
      "fallback_for_alpn": {
        "http/1.1": {
          "server": "127.0.0.1",
          "server_port": 8081
        }
      }    
    },
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 10808,
      "users": [
        {
          "uuid": "uuid",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "aws.amazon.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "aws.amazon.com",
            "server_port": 443
          },
          "private_key": "private_key",
          "short_id": "short_id"
        }
      }
    },
    {
      "type": "anytls",
      "tag": "anytls-in",
      "listen": "::",
      "listen_port": 8443,
      "tls": {
        "enabled": true,
        "certificate_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.crt",
        "key_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.key"
      },
      "users": [
        {
          "name": "name",
          "password": "password"
        }
      ]
    },
    {
      "type": "tuic",
      "tag": "tuic-in",
      "listen": "::",
      "listen_port": 8080,
      "users": [
        {
          "name": "name",
          "uuid": "uuid",
          "password": "password"
        }
      ],
      "congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "certificate_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.crt",
        "key_path": "/root/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/example.com/example.com.key"
      }
    },
    {
      "type": "shadowsocks",
      "tag": "ss-in",
      "method": "2022-blake3-aes-128-gcm",
      "password": "password"
    },
    {
      "type": "shadowtls",
      "tag": "st-in",
      "listen": "::",
      "listen_port": 1080,
      "detour": "ss-in",
      "version": 3,
      "users": [
        {
          "name": "name",
          "password": "password"
        }
      ],
      "handshake": {
        "server": "aws.amazon.com",
        "server_port": 443
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct"
    }
  ]
}
```
Замените name, password, example.com и private_key на cвои.

Отредактируйте systemd юнит sing-box:
```bash
sudoedit /usr/lib/systemd/system/sing-box.service
```
Сразу после [Service] добавьте строку User=root.

Включаем sing-box:
```bash
sudo systemctl daemon-reload 
sudo systemctl enable --now sing-box
```
