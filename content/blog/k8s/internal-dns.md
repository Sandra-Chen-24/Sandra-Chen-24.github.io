+++
date = "2026-02-10T16:30:00+08:00"
draft = false
title = "resolver"
description = ""
tags = ["resolver"]
categories = ["k8s"]
+++

## resolver 使用

- resolver 8.8.8.8 (Google 的公共 DNS):Google 的 DNS 伺服器並不知道內部網路的解析紀錄，因此會回傳 Host not found
- resolver kube-dns.kube-system [Kube DNS (CoreDNS)]:它是 K8s 集群內的『導航系統』，能即時追蹤所有 Service 的建立與刪除
- Local DNS (主機或節點 DNS):指 K8s 節點本身的 DNS 或外部網路的 DNS。只知道公網（如 Google、FB）或公司實體內網的網址。它無法解析 K8s 內部的 Service Name
