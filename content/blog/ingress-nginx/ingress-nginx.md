+++
date = "2025-12-11T11:30:00+08:00"
draft = false
title = "ingress-nginx"
description = ""
tags = ["ingress-nginx"]
categories = ["ingress-nginx"]
+++

## ingress-nginx vs nginx-ingress

- ingress-nginx (Kubernetes 官方) -> 安裝控制器本身，處理特定業務邏輯的 「Ingress 規則」需要另外建立 kind: Ingress 資源
  - 擴充性極強：內建了許多 Lua 腳本來處理像是 Prometheus 指標、動態平衡（Dynamic Load Balancing）等功能
  - 功能全開：許多進階功能（如 URL 重寫 Rewrite）直接透過 Annotation 就能用
  - annotation 前綴:nginx.ingress.kubernetes.io/
- nginx-ingress (NGINX/F5 官方)
  - 穩定與效能：配置更接近原生 NGINX，邏輯較簡單，執行更穩定
  - CRDs 管理：他們更傾向使用 VirtualServer 這種自定義資源來管理，而不是寫一堆長長的 Annotation
  - annotation 前綴:nginx.org/

## ingress-nginx to gateway

- 基礎設施定義:ingress-class -> GatewayClass
- 進入點/IP/TLS:ingress (metadata) -> Gateway
- 路由規則:ingress (rules) -> HTTPRoute

## ingress-nginx helm chart 4.7.1 (https://github.com/kubernetes/ingress-nginx/tree/main/charts/ingress-nginx)

[values.yaml](https://github.com/kubernetes/ingress-nginx/blob/helm-chart-4.7.1/charts/ingress-nginx/values.yaml)
[nginx-configuration](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)

- PodDisruptionBudget:.Values.controller.minAvailable

```text
# Source: ingress-nginx/templates/controller-poddisruptionbudget.yaml
.Values.controller.kind 為 Deployment
.Values.controller.autoscaling.enabled 為 true -> .Values.controller.autoscaling.minReplicas > 1
```

- ServiceAccount:{{- if or .Values.serviceAccount.create -}} 沒預設會預設建立

```text
# Source: ingress-nginx/templates/controller-serviceaccount.yaml
serviceAccount:
  create: true
  name: ""
  automountServiceAccountToken: true
  annotations: {}
```

- ClusterRole、ClusterRoleBinding、Role、RoleBinding

```text
# Source: ingress-nginx/templates/clusterrole.yaml
# Source: ingress-nginx/templates/clusterrolebinding.yaml
# Source: ingress-nginx/templates/controller-role.yaml
# Source: ingress-nginx/templates/controller-rolebinding.yaml
```

- ConfigMap:修改這些設定會直接影響整個叢集中所有透過該 Ingress Controller 進出的流量 [在 gateway 中轉換為 GCPBackendPolicy 或 FrontendConfig]

```text
# Source: ingress-nginx/templates/controller-configmap.yaml
# 安全性與權限 (Security)
allow-snippet-annotations:"true"，是否允許在個別的 Ingress 資源中使用 configuration-snippet 等註解來插入自定義 Nginx 設定
http-snippet:是一個非常強大的「後門」設定，直接將原生的 Nginx 配置代碼插入到 nginx.conf 檔案的 http 區塊（block）內
e.g.
    http-snippet: |
      server {
        listen 18080;
        location /nginx_status {
          allow all;
          stub_status on;
        }
        location / {
          return 404;
        }
      }
-> server: 對應特定的主機名（Host）。（由 server-snippet 設定）
-> location: 對應特定的路徑（Path）。（由 location-snippet 或 Ingress Annotation 設定）
ssl-dh-param:指定 Diffie-Hellman 演算法的密鑰檔案路徑，用於增強 SSL/TLS 的「完美遠向保密 (Perfect Forward Secrecy)」，防止舊的通訊內容在未來金鑰外洩時被破解

# 真實 IP 與標頭追蹤 (IP & Headers)
use-forwarded-headers:"true"，是否信任並傳遞 X-Forwarded-* 標頭
enable-real-ip:"true"，是否啟用 Nginx 的 ngx_http_realip_module 模組，將客戶端的 IP 替換為真實的來源 IP，而不是 Load Balancer 的內部 IP
proxy-real-ip-cidr:"0.0.0.0/0"代表完全信任，設定信任的代理伺服器 IP 範圍（CIDR），告訴 Nginx：「來自這些 IP（例如 GCP LB）的流量，請讀取其提供的真實來源 IP」
-> ⚠️ 建議只填入確定的負載平衡器 IP 範圍:
  GCP HTTP(S) Load Balancer：130.211.0.0/22 和 35.191.0.0/16
  Cloudflare：填入 Cloudflare 官方提供的 IP 範圍清單
-> proxy-real-ip-cidr: "130.211.0.0/22,35.191.0.0/16,10.128.0.0/20,203.0.113.5/32"
compute-full-forwarded-for:"true"，是否將目前的客戶端 IP 附加到 X-Forwarded-For 清單中，而不是直接覆蓋
add-headers & proxy-set-headers:全域性地在 HTTP 回應（Add）或轉發給後端服務（Set）時加入自定義 Header

# 日誌與後端管理 (Logging & Backend)
log-format-upstream:自定義發送給後端服務時的日誌格式，通常會加入 $upstream_response_time 等變數，用來監控後端服務的回應速度
e.g.
log-format-upstream: '{ "time_iso8601":"$time_iso8601", "http_x_forwarded_for":"$http_x_forwarded_for", "http_host":"$host", "method":"$request_method", "bytes_sent":"$bytes_sent", "pod_name":"$hostname", "path":"$request_uri", "parameters":"$args", "referrer":"$http_referer", "user_agent":"$http_user_agent", "remote_addr":"$remote_addr", "request_time":"$request_time", "request_uri":"$host$request_uri", "request_body":"$request_body", "response_time":"$upstream_response_time", "response_size":"$upstream_response_length", "status_code":"$status", "remote_user":"$remote_user", "time_local":"$time_local", "request":"$request", "body_bytes_sent":"$body_bytes_sent", "request_length":"$request_length", "proxy_upstream_name":"$proxy_upstream_name", "proxy_alternative_upstream_name":"$proxy_alternative_upstream_name", "upstream_addr":"$upstream_addr", "upstream_status":"$upstream_status", "req_id":"$req_id" }'
enable-access-log-for-default-backend:"true"，是否記錄「找不到路由 (404)」時導向 Default Backend 的訪問日誌
load-balance:設定負載平衡演算法（預設為 round_robin），可改為 least_conn (最少連接) 或 ewma (指數加權移動平均)，後者在微服務環境中通常能提供更穩定的延遲
```

- Service

```text
# controller-service-internal.yaml
.Values.controller.service.internal.annotations
{{- if and .Values.controller.service.enabled .Values.controller.service.internal.enabled .Values.controller.service.internal.annotations}}
->
controller:
    service:
        type: LoadBalancer
        enabled: true
        externalTrafficPolicy: Local
        enableHttp: true
        enableHttps: true
        ports:
          http: 80
          https: 443
        targetPorts:
          http: http
          https: https
        internal:
            enabled: true
            loadBalancerSourceRanges:
                - 10.0.0.0/8 # 預設內網網段全開
            loadBalancerIP: ""
            annotations:
                external-dns.alpha.kubernetes.io/hostname: template-ingress-internal-lb.out.in.qa.rdapp.vip
                networking.gke.io/load-balancer-type: Internal

# Source: ingress-nginx/templates/controller-service.yaml
# Source: ingress-nginx/templates/controller-service-metrics.yaml
# Source: ingress-nginx/templates/controller-service-webhook.yaml
```

- Deployment

```text
# Source: ingress-nginx/templates/controller-deployment.yaml
# Source: ingress-nginx/templates/controller-hpa.yaml
# Source: ingress-nginx/templates/controller-ingressclass.yaml [IngressClass]
# Source: ingress-nginx/templates/controller-prometheusrules.yaml [PrometheusRule]
# Source: ingress-nginx/templates/controller-servicemonitor.yaml [ServiceMonitor]

# Source: ingress-nginx/templates/admission-webhooks/validating-webhook.yaml [ValidatingWebhookConfiguration]
# Source: ingress-nginx/templates/admission-webhooks/cert-manager.yaml [Certificate]
# Source: ingress-nginx/templates/admission-webhooks/cert-manager.yaml [Issuer]
controller:
  admissionWebhooks:
    enabled: true
```

## 資源 kind: Ingress

```text
⭐⭐⭐ 全域攔截。當所有其他的 Ingress 規則（Host 或 Path）都匹配失敗時，會轉發到這裡
✨ 使用 spec.defaultBackend，沒有 rules 區塊，應到 nginx.conf 中的 default_server
# Source: php/templates/ingress-default-backend.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name:  template-default-backend
spec:
  ingressClassName: template-gateway
  defaultBackend:
    service:
      name: template-nginx
      port:
        name: http
  tls:
    - hosts:
        - ${host}
      secretName: wildcard-tls-rdapp-vip

⭐⭐⭐ 精確匹配。只有當請求的 Host 剛好等於 ${host} 且路徑為 / 時才生效
✨ 使用 spec.rules 區塊，定義明確的路由條件，對應到 nginx.conf 中的特定 server { server_name ${host}; }
# Source: php/templates/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: template
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: template-gateway
  tls:
    - hosts:
        - ${host}
      secretName: wildcard-tls-rdapp-vip
  rules:
    - host: ${host}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: template-nginx
                port:
                  name: http
```
