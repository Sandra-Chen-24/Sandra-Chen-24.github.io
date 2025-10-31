+++
date = "2025-10-31T15:30:00+08:00"
draft = false
title = "gateway api vs api gateway"
description = ""
tags = ["basic"]
categories = ["gateway"]
+++

## API Gateway

- 作為所有 API 請求的入口（entry point）
- 提供：
  - Routing（依路徑導向不同服務）
  - Authentication / Authorization
  - Rate limiting
  - Caching
  - Logging / Metrics
- 常見實作：
  - AWS API Gateway
  - Kong
  - NGINX Gateway
  - Istio Gateway（在 Service Mesh 架構中）

## Gateway API

[官方文件](https://gateway-api.sigs.k8s.io/)
[neg](https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg?hl=zh-tw#uses_with)
[t](https://hackmd.io/@QI-AN/Understanding-and-Implementing-the-Kubernetes-Gateway-API)

- Kubernetes 官方的新一代網路 API 標準，用來取代早期的 Ingress，是一組 Kubernetes CRD（Custom Resource Definition）
- 主要資源：[GatewayClass -> Gateway -> HTTPRoute -> Service 或 GatewayClass -> Gateway -> TLSRoute -> Service]
  - GatewayClass
  - Gateway -> 入口 IP
  - HTTPRoute
  - TCPRoute ?
  - UDPRoute ?
- 讓不同廠商（例如 Istio、NGINX、Traefik、HAProxy、Linkerd）可以共用同一套 Gateway 規範，達成：
  - 統一配置方式
  - 支援更細緻的路由規則
  - 支援多租戶、多 namespace 管理
  - 清楚分層：Infra team 管 Gateway，App team 管 Route
