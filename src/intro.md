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
Требуется VPS с дистрибутивом на базе systemd (например Debian).

## Подготовка:
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
