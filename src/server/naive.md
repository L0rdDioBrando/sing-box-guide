## Подготовка
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

## Компиляция Caddy
3. Собираем Caddy с нужным нам плагином:
```bash
export CADDY_VERSION=master
~/go/bin/xcaddy build --with github.com/caddyserver/forwardproxy@caddy2=github.com/klzgrad/forwardproxy@naive
sudo mv caddy /usr/bin/caddy
sudo chmod +x /usr/bin/caddy
```

## Редактирование
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
