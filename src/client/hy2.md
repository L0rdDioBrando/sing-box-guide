### 1. Устанавливаем Hy2 (ссылку можно заменить под вашу платформу):
```bash
wget https://download.hysteria.network/app/latest/hysteria-linux-amd64
```

### 2. Создайте config.yaml и вставте:
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

### 3. Запустите:
```bash
chmod +x ./hysteria-linux-amd64
./hysteria-linux-amd64
```
Запуск поднимет SOCKS5 прокси на 2080 порту и HTTP на 3128.
