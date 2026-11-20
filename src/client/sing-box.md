## Подготовка
Устанавливаем  и редактируем sing-box:
```bash
curl -fsSL https://sing-box.app/install.sh | sh -s -- --beta
sudoedit config.jsonc
```
## Редактирование
Вставляем конфиг:
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

Запускаем:
```bash
sudo sing-box run -c ./config.jsonc
```
