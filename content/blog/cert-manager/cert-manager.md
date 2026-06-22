+++
date = "2025-12-11T15:30:00+08:00"
draft = false
title = "cert-manager"
description = ""
tags = ["cert-manager"]
categories = ["cert-manager"]
+++

## 自動化申請免費的 Let's Encrypt 憑證

- 💡 運作原理：DNS-01 挑戰(Challenge)自動化
  1. cert-manager 產生一個隨機字符串
  2. 將該字符串以一條特殊的 TXT 紀錄的形式發佈到您的 DNS 服務器上
  3. 如果 Let's Encrypt 能夠在 DNS 服務器上找到這條正確的 TXT 紀錄，就證明您擁有網域，然後頒發憑證

- [Chart_cert-manager](https://charts.jetstack.io)
  - 是 Kubernetes 的自動憑證管理工具，最終與 Ingress 等資源整合，實現應用程式的 TLS 加密與自動續期，簡化 HTTPS 部署
  - 建立 Resource [roles, rolebindings, clusterroles, clusterrolebindings, serviceaccounts, deployment, service]
    - cert-manager：扮演著整個系統的大腦和協調者
      - 根據 Certificate 資源的定義，啟動與 ACME 伺服器 (如 Let's Encrypt) 溝通的流程
      - 負責創建 Challenge 資源（例如 DNS-01 挑戰），並等待 ExternalDNS 或 HTTP-01 服務完成驗證
      - 追蹤憑證的到期日，並在憑證到期前自動啟動續期流程
    - cert-manager-cainjector
      - 當 cert-manager 創建或更新自身的 CA 憑證時，cainjector 會自動將這些 CA 憑證注入到上述目標資源中，確保它們能夠正確地信任和與 cert-manager 的 Webhook (或其他服務) 進行 TLS 通訊
    - cert-manager-webhook：扮演著守門員的角色，確保只有有效的、格式正確的 cert-manager 資源才能進入 Cluster
      - 在使用者創建或修改 Certificate、Issuer 等資源時，在資源被寫入 etcd 之前，對其進行嚴格的驗證
  - 建立 CRDs
    - CertificateRequest
    - Certificate
    - Challenge
    - ClusterIssuer
    - Issuer
    - Order

- letsencrypt 設定
  - Issuer(頒發者):訂義憑證來源（如 Let's Encrypt、自簽）
    - Issuer 作用範圍為特定 Namespace
    - ClusterIssuer 作用範圍為整個 Cluster
      - 設定 solvers [external-dns]

        ```text
        # --- DNS-01 挑戰配置 ---
            solvers:
            - dns01:
                # cert-manager 將呼叫此 DNS 服務商的 API
                clouddns:
                  # 您的 GCP 專案 ID
                  project: my-gcp-project-id
        ```

  - Certificate:聲明你想要什麼樣的憑證（例如：example.com 的憑證），憑證簽發後會將 .crt (憑證) 和 .key (私鑰) 儲存為 Secret
    - 一旦 Certificate 資源被創建，cert-manager 就會啟動 DNS-01 流程，ExternalDNS 會自動在您的 DNS 服務商上創建 TXT 紀錄，完成驗證並自動頒發憑證到 my-app-tls-secret 中
    [Chart_external-dns](https://kubernetes-sigs.github.io/external-dns)
    -> 會自動建立 Cloud DNS 上的資訊
  - [Chart_Kubernetes-Reflector](https://github.com/emberstack/helm-charts)
    - [](https://github.com/emberstack/kubernetes-reflector)
    - 是一個專門設計用於自動化 Secret 和 ConfigMap 同步的控制器，允許在集中的 Namespace 中定義 Secret 或 ConfigMap，然後 Reflector 會將自動複製（或稱「反射」）到您指定的其他目標 (Target) Namespaces 中

    ```text
    # 有這個 annotations 就會同步到其他 ns
    annotations:
        reflector.v1.k8s.emberstack.com/auto-reflects: "True"
    ```


# 檢查憑證包含哪些 Domain
openssl x509 -in vgtpwsn.shop-crt.pem -noout -text | grep -A2 "Subject Alternative Name"
