## Подготовка
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

## Редактирование
3. Вставляем (Пароли лучше сгенерировать через openssl rand -hex 8):
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

4. Стартуем юнит hysteria:
```bash
sudo systemctl enable --now hysteria-server.service
```
