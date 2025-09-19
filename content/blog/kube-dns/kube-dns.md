+++
date = "2025-09-17T15:30:00+08:00"
draft = false
title = "kube-dns"
description = ""
tags = ["basic"]
categories = ["kube-dns"]
+++

## NodeLocalDNS

- dnsmasq_hits_count 跟 dnsmasq_misses_count 主要用來反映快取效益，命中就不需要往上游 CoreDNS/KubeDNS 或外部 DNS 查
- dnsmasq_hits_count / (dnsmasq_hits_count + dnsmasq_misses_count) * 100
  -> 如果命中率 > 80%，代表大部分的查詢都被快取解決

## kube-dns-autoscaler 的設定

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns-autoscaler
  namespace: kube-system
data:
  linear: |-
    {
      "coresPerReplica": 256,
      "nodesPerReplica": 16,
      "min": 2,
      "max": 20
    }

🔹 coresPerReplica: 每多少個 CPU Core 需要新增一個 CoreDNS 副本
🔹 nodesPerReplica: 每多少個 Node 需要新增一個副本
👉 autoscaler 會取兩者中 需要副本數較多的那個值

🔹 min: kube-dns/CoreDNS 最少副本數 (避免過小集群無法容錯)
🔹 max: kube-dns/CoreDNS 最大副本數 (避免太多 pod 浪費資源)

📌 實際例子
假設你的 cluster 有：
640 cores / 80 nodes

計算：
coresPerReplica = 256 → 640 / 256 = 3 副本
nodesPerReplica = 16 → 80 / 16 = 5 副本
👉 autoscaler 選取 5 副本 (因為要滿足兩個條件中較大的需求)
```
