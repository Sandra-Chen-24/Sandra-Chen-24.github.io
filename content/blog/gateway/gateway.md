+++
date = "2025-09-18T15:30:00+08:00"
draft = false
title = "權限相關"
description = ""
tags = ["gateway"]
categories = ["gcp"]
+++

[secure-gateway](https://cloud.google.com/kubernetes-engine/docs/how-to/secure-gateway?hl=zh-tw)
[gateway-management](https://cloud.google.com/kubernetes-engine/docs/concepts/gateway-security#gateway-management)

- 確保你的 GKE 版本在 1.24 以上，啟動 Gateway API 功能[大概要三分鐘]

  ```text
  gcloud container clusters update [CLUSTER_NAME] --gateway-api=standard --zone [ZONE] --project [PROJECT_ID]

  [檢查]
    ❯ kubectl get crd | grep gateway.networking.k8s.io
    gatewayclasses.gateway.networking.k8s.io
    gateways.gateway.networking.k8s.io
    httproutes.gateway.networking.k8s.io
    referencegrants.gateway.networking.k8s.io

    ❯ kubectl get gatewayclass
    NAME                               CONTROLLER                  ACCEPTED
    gke-l7-global-external-managed     networking.gke.io/gateway   True
    gke-l7-gxlb                        networking.gke.io/gateway   True
    gke-l7-regional-external-managed   networking.gke.io/gateway   True
    gke-l7-rilb                        networking.gke.io/gateway   True
  ```

[GatewayClass 介紹](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/gatewayclass-capabilities?hl=zh-tw)

- GatewayClass
  - gke-l7-global-external-managed:全域外部，面向全球用戶，需要 Google Edge 緩存/WAF (Cloud Armor)
  - gke-l7-gxlb:經典全域外部，舊版架構（Classic），除非有特殊相容性需求，否則優先選上面的 Managed 版本
  - gke-l7-regional-external-managed：區域外部，僅服務特定地區（如台灣），需要符合資料在地化法規
  - gke-l7-rilb:內部 (Internal)，VPC 內部、叢集內部服務互通
