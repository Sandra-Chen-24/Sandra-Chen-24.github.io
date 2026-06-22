+++
date = "2026-06-16T10:30:00+08:00"
draft = false
title = "指標收集使用 GMP"
description = ""
tags = ["gmp"]
categories = ["gcp"]
+++



維度/步驟	核心操作流程 / 設定語法	關鍵費用注意與坑點（非常重要！）	Excel 維運備註說明
1. Cluster 開設定 (啟用託管蒐集)	使用 gcloud 指令或在主控台勾選啟用：\n`gcloud container clusters update <叢集名稱> --enable-managed-prometheus --region <區域>`	**啟用此設定本身是免費的**，GCP 會自動在你的 Node 上生出 `gmp-operator` 與 `collector` 容器。\n⚠️ **注意：** 啟用後它會預設自動收集 K8s 系統指標（如 cAdvisor、kube-state-metrics），這部分會**開始產生指標寫入費用**！	這是最底層的開關，開啟後叢集才具備接收 Prometheus 指標的能力。
2. 裝 Adapter (對接自訂監控)	如果是要跑 HPA (自動伸縮) 或者是讓既有的 Prometheus 服務對接，需要部署 **Custom Metrics Stackdriver Adapter**：\n`kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml`	Adapter 本身部署在 K8s 內，會吃掉少量的 Node 運算資源（CPU/RAM）。\n⚠️ **注意：** 如果頻繁地透過 Adapter 撈取、轉發大量自訂指標，可能會無形中增加 API 的呼叫次數與網路傳輸。	如果只是單純想把指標倒進 Cloud Monitoring 看看板，不需要裝這個；如果要連動 HPA 自動長機器才需要裝。
3. 過濾 Metric (控管成本的核心)	透過設定 **`ClusterPodMonitoring`** 或 **`PodMonitoring`** CRD，在 `metrics` 欄位中使用 `keep` 或 `drop` 來篩選：\n
http://googleusercontent.com/immersive_entry_chip/0

---

### 💸 補充：GMP 帳單優化三大心法

在 Excel 做預算評估時，請務必把以下三點列入考量：

1. **基本額度 (Free Tier)**：
   GCP 每個月通常會提供每個帳號大約 1,000 萬到 5,000 萬個免費的指標樣本額度（具體依官方最新公告為準）。對於開發與測試環境，只要不過度揮霍，基本上可以壓在免費額度內。

2. **如何監控 GMP 的花費？**：
   你可以在 Cloud Billing（計費）報告中，篩選產品為 **"Stackdriver"** 或 **"Cloud Monitoring"**，並尋找 SKU 名稱為 **"Managed Service for Prometheus Samples Ingested"** 的項目，就能實時追蹤到底是哪一個 K8s 命名空間在瘋狂燒錢。

3. **抓漏指令（看誰噴最多指標）**：
   開啟監控後，如果發現費用暴增，可以在 GCP 的 Metrics Explorer 裡下這行 PromQL，直接抓出誰是吃錢怪獸：
   ```promql
   sum by (metric_name) (rate(prometheus_googlediscovery_active_series[5m]))