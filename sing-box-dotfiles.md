Это мой гайд по настройке [sing-box](https://github.com/SagerNet/sing-box) для обхода блокировок. Много чего взял [отсюда](https://gist.github.com/swrneko/09e60de4d3d8f9a551a1a2c1ab9283c5).

## Поддерживаемые протоколы:
  - [NaiveProxy](https://github.com/klzgrad/naiveproxy)

  - [Trojan](https://github.com/trojan-gfw/trojan)

  - [VLESS](https://xtls.github.io/ru/development/protocols/vless.html)+[Reality](https://xtls.github.io/ru/config/transports/reality.html)

  - [Hysteria2](https://v2.hysteria.network)

  - [AnyTLS](https://github.com/anytls/anytls-go)

  - [TUIC](https://github.com/tuic-protocol/tuic)

  - [Shadowsocks](https://github.com/shadowsocks/shadowsocks-rust)+[ShadowTLS](https://github.com/ihciah/shadow-tls)

  - [MASQUE](https://datatracker.ietf.org/doc/html/rfc9484)

## Подготовка:
Требуется VPS с дистрибутивом на базе systemd (например Debian).

1. Установите ваш редактор по умолчанию (например vim или nano):
```bash
sudo update-alternatives --config editor
```

2. Включаем BBR:
```bash
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_slow_start_after_idle=0" | sudo tee -a /etc/sysctl.conf # Уменьшает количество подлагиваний
echo "net.ipv4.tcp_notsent_lowat=131072" | sudo tee -a /etc/sysctl.conf # Лимит на объем неотправленных данных
sudo sysctl -p
```

## Установка NaiveProxy на сервер:
1. Ставим Go:
```bash
export GO_VER=$(curl --silent "https://go.dev/VERSION?m=text" | head -n 1)
wget https://go.dev/dl/$GO_VER.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $GO_VER.linux-amd64.tar.gz && rm -rf $GO_VER.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile
```

2. Устанавливаем XCaddy чтобы собрать Caddy с плагином от автора NaiveProxy:
```bash
go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
```

3. Собираем Caddy с нужным нам плагином:
```bash
export CADDY_VERSION=master
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
sudo mv caddy /usr/bin/caddy
sudo chmod +x /usr/bin/caddy
```

4. Создаём папку Caddy и редактируем конфиг (нужен свой домен зарегестрированный на IP адрес сервера, но можно зарегистрировать бесплатный на FreeDNS или DuckDNS):
```bash
sudo mkdir /etc/caddy
sudo touch /etc/caddy/Caddyfile
sudoedit /etc/caddy/Caddyfile
```

5. Вставляем такое содержимое (замените example.com, email, user и pass на ваши):
```caddyfile
{
  order forward_proxy before file_server
  log {
    exclude http.log.error
    output file /var/log/caddy/access.log {
      roll_size 10mb
    }
  }
}

:443, example.com { # Ваш домен
  tls email@example.com # Почта с которой регали домен
  encode
  forward_proxy {
    basic_auth user pass # Логин и пароль (лучше сгенерировать через openssl rand -hex 8)
    hide_ip
    hide_via
    probe_resistance
  }
  file_server {
    root /var/www/html
  }
}
```

6. Создаём systemd юнит для автозагрузки caddy:
```bash
sudo touch /etc/systemd/system/caddy.service 
sudo cat <<EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF
```

7. Включаем Caddy:
```bash
sudo systemctl daemon-reload
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
```

## Установка Hysteria2 на сервер:
1. Устанавливаем Hysteria2:
```bash
bash <(curl -fsSL https://get.hy2.sh/)
```

2. Редактируем конфиг для Hy2:
```bash
sudo mkdir /etc/hysteria
sudo touch /etc/hysteria/config.yaml
sudoedit /etc/hysteria/config.yaml
```

3. И вставляем (Пароли лучше сгенерировать через openssl rand -hex 8):
```yaml
listen: :1234

acme:
  domains:
    - example.com # Ваш домен
  email: email # Почта с которой регистрировали домен

auth:
  type: password
  password: hy2_pass # Пароль от Hy2

obfs:
  type: gecko
  gecko:
    password: obfs_pass # Пароль от обфускации
    minPacketSize: 512  
    maxPacketSize: 1200  

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true
```

4. Стартуем hysteria:
```bash
sudo systemctl enable --now hysteria-server.service
```

## Установка sing-box на сервер:
1. Теперь ставим sing-box:
```bash
curl -fsSL https://sing-box.app/install.sh | sh -s -- --beta
```

2. Генерируем нужные значения:
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

8. Редактируем конфиг:
```bash
sudoedit /etc/sing-box/config.json
```

9. Вставьте (если тут уже что-то было удалите):
```jsonc
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
Замените example.com и private_key на ваш домен и приватный ключ.

10. Отредактируйте systemd юнит sing-box:
```bash
sudoedit /usr/lib/systemd/system/sing-box.service
```
Сразу после [Service] добавте строку User=root.

11. Включаем sing-box:
```bash
sudo systemctl daemon-reload 
sudo systemctl enable --now sing-box
```

12. Открываем все необходимые порты (команда только для ufw):
```bash
sudo ufw enable
sudo ufw allow 443 
sudo ufw allow 80
sudo ufw allow 20808
sudo ufw allow 10808
sudo ufw allow 1234
sudo ufw allow 8443
sudo ufw allow 8080
sudo ufw allow 1080
sudo ufw allow 500
```

## Установка NaiveProxy на клиент:
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

## Установка Hysteria2 на клиент:
1. Устанавливаем Hy2 (ссылку можно заменить под вашу платформу):
```bash
wget https://download.hysteria.network/app/latest/hysteria-linux-amd64
```

2. Создайте config.yaml и вставте:
```yaml
server: IP:1234 # Замените IP на IP сервера

auth: hy2_pass # Пароль от Hy2

tls:
  sni: example.com # Ваш домен

obfs:
  type: gecko
  gecko:
    password: obfs_pass # Пароль от обфускации
    minPacketSize: 512  
    maxPacketSize: 1200

bandwidth: # Можно менять в зависимости от скорости вашего интернета
  up: 100 mbps
  down: 300 mbps

socks5:
  listen: 127.0.0.1:2080

http:
  listen: 127.0.0.1:3128

lazy: true
```

3. Запустите:
```bash
chmod +x ./hysteria-linux-amd64
./hysteria-linux-amd64
```
Запуск поднимет SOCKS5 прокси на 2080 порту и HTTP на 3128.

## Установка sing-box на клиент:
1. Устанавливаем  и редактируем sing-box:
```bash
curl -fsSL https://sing-box.app/install.sh | sh -s -- --beta
sudoedit config.jsonc
```

2. Вставляем конфиг:
```jsonc
{
  "$schema": "https://sing-box.sagernet.org/schema.json",
  "log": {
    "level": "debug"
  },
  "dns": {
    "servers": [
      {
        "type": "h3",
        "tag": "dns",
        "detour": "selector",
        "server": "1.1.1.1",
        "tls": {
          "server_name": "cloudflare-dns.com"
        }
      }
    ],
    "strategy": "ipv4_only" // Можете удалить строку если у вас поддерживается IPv6
  },
  "endpoints": [
    {
      "type": "masque-client",
      "tag": "masque-client",
      "server": "server_IP",
      "server_port": 500,
      "username": "username",
      "password": "password",
      "tls": {
        "enabled": true,
        "server_name": "example.com"
      },
      "version": 3,
      "disable_version_fallback": true,
      "on_demand": true,
      "disable_path_mtu_discovery": true
    }
  ],
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "mtu": 1280,
      "address": "172.19.0.1/30",
      "auto_route": true,
      "strict_route": true,
      "route_exclude_address": [
        "server_IP/32"
      ],
      "exclude_package": [
        "com.android.captiveportallogin",
        "ru.oneme.app"
      ]
    }
  ],
  "outbounds": [
    {
      "type": "naive",
      "tag": "naive-out",
      "server": "server_IP",
      "server_port": 443,
      "username": "username",
      "password": "password",
      "insecure_concurrency": 1,
      "udp_over_tcp": true,
      "quic": true, // Можете убрать чтобы использовался HTTP/2
      "quic_congestion_control": "bbr",
      "tls": {
        "enabled": true,
        "server_name": "example.com"
      }
    },
    {
      "type": "trojan",
      "tag": "trojan-out",
      "server": "server_IP",
      "server_port": 20808,
      "password": "password",
      "tls": {
        "enabled": true,
        "server_name": "example.com",
        "utls": {
          "enabled": true,
          "fingerprint": "firefox"
        }
      }
    },
    {
      "type": "vless",
      "tag": "vless-out",
      "server": "server_IP",
      "server_port": 10808,
      "uuid": "uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "aws.amazon.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "public_key",
          "short_id": "short_id"
        }
      },
      "packet_encoding": "xudp"
    },
    {
      "type": "hysteria2",
      "tag": "hy2-out",
      "server": "server_IP",
      "server_port": 1234,
      "up_mbps": 100,
      "down_mbps": 300,
      "obfs": {
        "type": "gecko",
        "password": "password"
      },
      "password": "password",
      "tls": {
        "enabled": true,
        "server_name": "example.com"
      }
    },
    {
      "type": "anytls",
      "tag": "anytls-out",
      "server": "server_IP",
      "server_port": 8443,
      "tls": {
        "enabled": true,
        "server_name": "example.com"
      },
      "password": "password",
      "idle_session_check_interval": "30s",
      "idle_session_timeout": "30s",
      "min_idle_session": 5
    },
    {
      "type": "tuic",
      "tag": "tuic-out",
      "server": "server_IP",
      "server_port": 8080,
      "uuid": "uuid",
      "password": "password",
      "congestion_control": "bbr",
      "udp_relay_mode": "native",
      "tls": {
        "enabled": true,
        "server_name": "example.com"
      }
    },
    {
      "type": "shadowtls",
      "tag": "st-out",
      "server": "server_IP",
      "server_port": 1080,
      "version": 3,
      "password": "password",
      "tls": {
        "enabled": true,
        "server_name": "aws.amazon.com"
      }
    },
    {
      "type": "shadowsocks",
      "tag": "ss-out",
      "detour": "st-out",
      "method": "2022-blake3-aes-128-gcm",
      "password": "password"
    },
    {
      "type": "selector",
      "tag": "selector",
      "outbounds": [
        "naive-out",
        "trojan-out",
        "vless-out",
        "hy2-out",
        "anytls-out",
        "tuic-out",
        "ss-out",
        "masque-client"
      ],
      "default": "hy2-out" // Тут меняются протоколы
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "action": "sniff",
        "sniffer": [
          "http",
          "tls",
          "dns",
          "quic"
        ],
        "timeout": "300ms"
      },
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
      {
        "action": "resolve",
        "server": "dns"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "domain_suffix": [
          ".ru"
        ],
        "domain_keyword": [
          "github"
        ],
        "outbound": "direct"
      },
      {
        "process_name": [
          "ssh",
          "git"
        ],
        "outbound": "direct"
      }
    ],
    "final": "selector",
    "auto_detect_interface": true,
    "default_domain_resolver": "dns"
  }
}
```
Замените:
- server_IP на IP адрес вашего VPS.
- public_key на публичный ключ сгенерированный вместе с приватным.
- username, password, uuid, short_id на теже самые что и на сервере.
- example.com на ваш домен.

3. Запускаем:
```bash
sudo sing-box run -c ./config.jsonc
```

## Установка на Android:
Скачиваем .apk файл с последнего [пре-релиза](https://github.com/SagerNet/sing-box/releases) и устанавливаем. Перекидываем конфиг на телефон и заходим в sing-box. Нажимаем на + и выбираем "Импорт из файла". Импортируем конфиг и подключаемся.

## Как менять протоколы:
В selector поменяйте значение default на тег какого либо из протоколов (они перечислены блоком выше).

## Альтернативные клиенты:
На Windows и Linux: [Throne](https://throneproj.github.io/ru/), [NekoBox](https://github.com/qr243vbi/nekobox) и [Sing-box-For-Desktop](https://github.com/SagerNet/sing-box-for-desktop). На Android: [NekoBox For Android](https://github.com/MatsuriDayo/NekoBoxForAndroid).
