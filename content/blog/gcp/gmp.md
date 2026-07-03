+++
date = "2026-06-16T10:30:00+08:00"
draft = false
title = "指標收集使用 GMP"
description = ""
tags = ["gmp"]
categories = ["gcp"]
+++


## 設定步驟
1. Cluster 開設定 (啟用託管蒐集)

```text
## 使用 gcloud 指令或在主控台勾選啟用 [啟用此設定本身是免費的 👉 GCP 會自動在你的 Node 上生出 `gmp-operator` 與 `collector` 容器]
⚠️ 啟用後它會預設自動收集 K8s 系統指標（如 cAdvisor、kube-state-metrics）[開始產生指標寫入費用]
gcloud container clusters update <叢集名稱> --enable-managed-prometheus --region <區域>
```

2. 裝 Adapter (對接自訂監控)	如果是要跑 HPA (自動伸縮) 或者是讓既有的 Prometheus 服務對接

```text
## 部署 Custom Metrics Stackdriver Adapter
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml
👉 要連動 HPA 自動擴縮才需要裝
⚠️ 如果頻繁地透過 Adapter 撈取、轉發大量自訂指標，可能會無形中增加 API 的呼叫次數與網路傳輸
⚠️ 只是單純想把指標倒進 Cloud Monitoring 看看板不需要裝 Adapter
```

3. 過濾 Metric (控管成本的核心)

```text
## 設定 ClusterPodMonitoring 或 PodMonitoring 的 CRD
👉 在 metrics 欄位中使用 `keep` 或 `drop` 來篩選
http://googleusercontent.com/immersive_entry_chip/0
```

4. 安裝 Grafana

```text
## 新增 Grafana 的 Helm 儲存庫
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
```

```text
## 用版控
/grafana/Chart.yaml
apiVersion: v2
name: grafana
description: A Helm chart for my Kubernetes monitoring stack including Grafana
type: application

version: 1.0.0
appVersion: "1.0.0"

dependencies:
  - name: grafana
    version: 12.4.9
    repository: "https://grafana-community.github.io/helm-charts"
    # condition: grafana.enabled # 可選，允許未來在 values.yaml 中動態開關此組件

## 查詢官方目前的最新版本號 [看 CHART VERSION 那一欄]
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo update
helm search repo grafana-community/grafana --versions | head -n 5

👉 helm dependency update . [把 chart 拉回專案]
```

```text
## 安裝
kubectl create namespace monitoring
helm install grafana grafana-community/grafana --namespace monitoring

## 登入帳密
帳號:admin
密碼：kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

## 權限
前往 IAM & Admin -> Service Accounts（服務帳號）
建立一個服務帳號（例如 grafana-gmp-reader），並賦予它這個角色：
角色：Monitoring Viewer（監控檢視者）
建立完成後，點進該帳號，選擇 Keys -> Add Key -> Create new key，下載 JSON 格式的金鑰檔案

## 在 Grafana 設定 Data Source
打開 Grafana，前往 Connections -> Data sources -> Add data source。
搜尋並選擇 Google Cloud Monitoring（這是 Grafana 內建的原生 Data Source）。
設定認證方式 (Authentication)：
選擇 JWT File。
把你剛剛在第一步下載的 GCP JSON 金鑰內容 整個複製貼進來。
點擊 Save & test，看到成功連線即可
```

## 💸 補充：GMP 帳單優化三大心法

1. 基本額度 (Free Tier)：GCP 每個月通常會提供每個帳號大約 1,000 萬到 5,000 萬個免費的指標樣本額度
2. 如何監控 GMP 的花費？
👉 在 Cloud Billing 報告中，篩選產品為 Stackdriver 或 Cloud Monitoring，並尋找 SKU 名稱為 Managed Service for Prometheus Samples Ingested 的項目
3. 抓漏指令（看誰噴最多指標）：在 GCP 的 Metrics Explorer 裡下這行 PromQL
```promql
sum by (metric_name) (rate(prometheus_googlediscovery_active_series[5m]))
```

## 接收 VM 中 REDIS 指標

在 VM 內啟動 redis_exporter

```text
# 下載並解壓（請根據需要選擇版本）
wget https://github.com/oliver006/redis_exporter/releases/download/v1.55.0/redis_exporter-v1.55.0.linux-amd64.tar.gz
tar -xvf redis_exporter-v1.55.0.linux-amd64.tar.gz

# 在背景執行（如果 Redis 有密碼，請加上 -redis.password "你的密碼"）
nohup ./redis_exporter-v1.55.0.linux-amd64/redis_exporter &
⚠️ 實務盲點：用 nohup 留下的隱藏垃圾
當你執行 nohup ./redis_exporter ... & 時，Linux 預設會在你的當前目錄下自動產生一個叫做 nohup.out 的日誌檔案。
👉 潛在風險：redis_exporter 每隔 30 秒被 Ops Agent 刮一次資料，它就會在 nohup.out 裡面記下一行 Log。這隻 VM 如果跑了半年、一年，這個 nohup.out 就會默默長大到幾 GB 甚至幾十 GB，最終把你的 VM 硬碟空間完全撐爆
```

```text
💡 改善做法：建立一個 systemd 服務設定檔
sudo cp redis_exporter-v1.55.0.linux-amd64/redis_exporter /usr/local/bin/
sudo touch /etc/systemd/system/redis_exporter.service

## /etc/systemd/system/redis_exporter.service
[Unit]
Description=Redis Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/redis_exporter -web.listen-address :9121 -redis.password "aaa"
Restart=on-failure

[Install]
WantedBy=multi-user.target

# 重新載入系統服務
sudo systemctl daemon-reload

# 啟動 Redis Exporter
sudo systemctl start redis_exporter
sudo systemctl status redis_exporter

# 設定開機自動啟動（防止 VM 哪天死機重啟後監控直接斷線）
sudo systemctl enable redis_exporter

⭐ 用 curl http://localhost:9121/metrics 確認
```

[修改 Ops Agent 設定檔](https://docs.cloud.google.com/stackdriver/docs/solutions/agents/ops-agent/prometheus?hl=zh-cn)

```text
# 預設路徑為 /etc/google-cloud-ops-agent/config.yaml
📋 加上這段設定，不會關閉原本預設的 VM CPU 和記憶體監控
metrics:
  receivers:
    redis_prometheus:
      type: prometheus
      config:
        scrape_configs:
          - job_name: 'redis_vm'
            scrape_interval: 60s
            static_configs:
              - targets: ['localhost:9121']
            <!-- relabel_configs:
              - source_labels: [__address__]
                target_label: pod
                replacement: 'slot-prod-server-as-redis' -->
            metric_relabel_configs:
              # 1. 保留你指定的那 9 個核心指標
              - source_labels: [__name__]
                regex: '^(redis_connected_clients|redis_memory_used_bytes|redis_memory_max_bytes|redis_mem_fragmentation_ratio|redis_commands_processed_total|redis_keyspace_hits_total|redis_keyspace_misses_total|redis_uptime_in_seconds|redis_up)$'
                action: keep
  service:
    pipelines:
      redis_pipeline:
        receivers: [redis_prometheus]
```

重啟 Ops Agent 服務

```text
sudo systemctl restart google-cloud-ops-agent
```
