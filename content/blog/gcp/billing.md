+++
date = "2026-07-09T10:30:00+08:00"
draft = false
title = "費用計算"
description = ""
tags = ["billing"]
categories = ["gcp"]
+++

## Networking

```text
⭐ Cloud Load Balancer Forwarding Rule Minimum Global：前 5 個 Forwarding Rules 共享一個固定基本費($0.025 USD / hr)
⭐ Cloud Load Balancer Forwarding Rule Additional Global：第 6 個起每一個規則 $0.010 USD / hr
⭐ Cloud Load Balancer Forwarding Rule Minimum for Taiwan (asia-east1)：區域型（Regional）負載平衡器，同樣是前 5 個規則共用 $0.025 USD / hr
⭐ Networking Cloud Armor Requests：採取「計次收費」，每 100 萬個請求 $0.75 USD
⭐ Networking Cloud Nat Gateway Uptime：這是 Cloud NAT 閘道器的月租費，建立了不論有沒有流量經過都會按時計費($0.045 USD / hr)
⭐ Cloud Armor rules：沒有任何免費額度，每個安全政策（Policy）：每月 $5.00 USD，每個規則（Rule）：每月 $1.00 USD
⭐ VM Manager Usage (Cloud Ops)：代表專案中啟用了 Google Cloud 的 VM Manager 自動化運維工具
- 補丁管理 (Patch Management)
- 配置管理 (OS Config / Configuration Management)
- 軟體清單盤點 (OS Inventory Management)
- goog-ops-agent-policy
```

## Google Cloud Logging

```text
👉 每月前 50 GiB 的 Log 儲存完全免費，超過免費額度，收費會拆成兩個階段：
- Log 擷取與儲存費用：每 GiB 約 $0.50 USD，包含了預設 30 天的保留期
- 延長保留費用：每 GiB 每月約 $0.01 USD，從第 31 天開始，就會額外收取
⚠️ 完全免費的 Log 種類：有些系統產生的內部 Log 是完全不計入 50 GiB 的額度，也永遠不收費的
- Cloud Audit Logs（雲端稽核日誌）：包括 Admin Activity（管理員操作紀錄）、System Event（系統事件）[⚠️ Data Access 不在免費範圍內，它的量通常極大，需要小心監控]
- Access Transparency Logs（存取透明度日誌）


⚠️ 看到 VM 有噴 jsonPayload.message=~" rsyslogd" [Redis & Gitlab]
df -h # 檢查硬碟容量
👉 抓出硬碟空間被什麼大檔案吃掉了
sudo du -sh /var/log/* | sort -rh | head -n 10
👉 889M /var/log/journal [這是 Linux 系統內建 systemd-journald 儲存二進位日誌的地方]
👉 journalctl -n 10 [查看近 10 筆資料]
👉 journalctl | head -n 10 [看最前面的 10 筆資料]
🛠️ 強制限制並清理 Systemd Journal 日誌
sudo journalctl --vacuum-size=100M
🛠️ 修改設定檔，讓它不准超過 100M
sudo vi /etc/systemd/journald.conf
SystemMaxUse=100M
sudo systemctl restart systemd-journald
🛠️ 重啟 rsyslog 服務（中斷卡死循環）
sudo systemctl restart rsyslog

df -i # 檢查 Inodes 是否 100% (極重要)
👉 檢查正常

⚠️ 看到 VM 有噴 jsonPayload.message=~"otelopscol" [Redis]
👉 可能同時跑了兩個一模一樣的監控實例
ps aux | grep -E "otel|fluent"
⭐ 檢查沒有跑一樣的實例
# 重啟 GCP Ops Agent，徹底重置打架的監控緩衝區
sudo systemctl restart google-cloud-ops-agent
```


## Kubernetes Engine

```text
⭐ Zonal Kubernetes Clusters：
- 控制面管理費($0.10 USD / hr)，每個月會提供一個叢集的免費額度
```

## Cloud SQL

```text
⭐ IOPS 效能主要受 「磁碟容量 (GB)」 與 「執行個體 CPU (vCPU)」 雙重限制，最終的實際上限是取兩者的較小值

效能指標                 算式 / 增量
Read / Write IOPS       30 IOPS / GB
Write Throughput        0.48 MiB/s / GB
Read Throughput         0.48 MiB/s / GB


vCPU 核心數    Zonal（單區）最高 IOPS 上限    Regional（HA 雙區）最高 IOPS 上限    吞吐量上限
1 vCPU        15,000 IOPS                  15,000 IOPS                       200 MiB/s
2 – 7 vCPU    15,000 IOPS                  15,000 IOPS                       240 MiB/s
8 – 15 vCPU   15,000 IOPS                  15,000 IOPS                       800 MiB/s

-> 512 GB 的磁碟算出來已經是 512 * 30 = 15,360 IOPS，其實已經觸頂 15,000 IOPS
```
