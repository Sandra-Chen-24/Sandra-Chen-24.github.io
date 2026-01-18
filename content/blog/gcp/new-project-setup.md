+++
date = "2026-01-18T15:30:00+08:00"
draft = false
title = "新 GCP 環境建置"
description = ""
tags = ["basic"]
categories = ["gcp"]
+++

## 防火牆 - 建議設定的 IP 白名單範圍

```text
# Google Health Check
130.211.0.0/22
35.191.0.0/16
TCP 80

# allow-ingress-from-iap
35.235.240.0/20
所有來自 IAP 的 SSH (TCP 22) 或 RDP (TCP 3389) 流量都會從這個範圍發出
```

## Cloud Router & Cloud NAT 的用途

```text
Cloud Router 是一個全代管的虛擬路由器，它不處理實際的數據流量封包（Data Plane），而是負責交換路由資訊（Control Plane）
- 動態路由交換 (BGP)：當你的 VPC 透過 Cloud VPN 或 Dedicated Interconnect 連接到地端機房時，Cloud Router 會使用 BGP 協定自動學習和傳播路由，不需要手動設定靜態路由。
- 網路連通性的基礎：它決定了封包「該往哪裡走」
- 服務支撐：它是 Cloud NAT 運作的先決條件。沒有 Cloud Router，就無法啟用 Cloud NAT

Cloud NAT 允許沒有外部 IP 位址的資源（如私有子網中的 VM 或 GKE 節點）連接到網際網路
- 單向連外：內網機器可以主動連出去更新軟體或存取 API，但外部網路的黑客無法主動連入這台機器（因為它沒有公開的外部 IP）
- 節省外部 IP：多個虛擬機可以共用一個（或一組）外部 IP 位址
- 安全性：隱藏內部機器的真實 IP
```
