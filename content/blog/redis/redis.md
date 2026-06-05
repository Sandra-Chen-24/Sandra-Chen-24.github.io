+++
date = "2026-05-15T10:00:00+08:00"
draft = false
title = "Redis 調整最大 client 數量"
description = ""
tags = ["redis"]
categories = ["DB"]
+++

## 尋找服務名稱
systemctl list-units --type=service | grep redis
-> redis.service

## LimitNOFILE 設定 [default:10032]
sudo vi /etc/systemd/system/redis.service

```text
[Service]
LimitNOFILE=20000
```
## tcp-backlog 設定 [default:511]
sudo vi /usr/local/redis/redis.conf

## 重啟 REDIS
sudo systemctl daemon-reload
sudo systemctl restart redis

### 確認當下REDIS設定 
redis-cli -a ${PWD} info clients
redis-cli -a ${PWD} CONFIG GET maxclients

## 調整 Linux system 設定
sudo vi /etc/sysctl.d/99-sysctl.conf

net.core.somaxconn            default:4096
net.ipv4.tcp_max_syn_backlog  default:512
net.core.netdev_max_backlog   default:1000
net.ipv4.tcp_keepalive_time   default:7200
net.ipv4.tcp_keepalive_intvl  default:75
net.ipv4.tcp_keepalive_probes default:9


### 確認當下環境設定 sysctl ${參數名稱}
e.g. sysctl net.core.somaxconn
