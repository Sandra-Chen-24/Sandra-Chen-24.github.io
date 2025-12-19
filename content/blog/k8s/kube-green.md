+++
date = "2025-12-18T11:30:00+08:00"
draft = false
title = "kube-green"
description = ""
tags = ["cost"]
categories = ["k8s"]
+++


## [kube-green](https://kube-green.dev/docs/getting-started/)

- Install [Helm Charts](https://kube-green.github.io/helm-charts/)
  - [Values](https://github.com/kube-green/kube-green/blob/main/charts/kube-green/values.yaml)

```text
repositories:
  # https://kube-green.dev
  - name: kube-green
    url: https://kube-green.github.io/helm-charts

templates:
  kube-green: &kube-green
    namespace: kube-green
    chart: kube-green/kube-green
    version: 0.7.1
```

- 服務組成
  - Deployment [kube-green-controller-manager]
    - 使用憑證 metrics-server-cert & webhook-server-cert
    - Service
      - kube-green-controller-manager-metrics-service
      - kube-green-webhook-service
  - Certificate：webhooks require a valid certificate to expose the webhook server to the Kubernetes API server
    - kube-green-metrics-certs
    - kube-green-serving-cert
    - Issuer [kube-green-selfsigned-issuer]
  - ValidatingWebhookConfiguration：是 Kubernetes 中的「守門員」機制，是 Admission Controller 的一部分，在資源（例如 Pod, Deployment,SleepInfo）被寫入 etcd 之前，先將該資源發送給一個外部服務進行「審核」
    - 運作流程：攔截與審查

    ```text
    執行 kubectl apply 時，請求會經過以下階段：
    ✨ Authentication & Authorization：確認是否有權限
    ✨ Mutating Admission：自動修改資源（例如自動注入 Sidecar）
    ✨ Object Validation：基本的語法檢查
    ✨ Validating Admission：API Server 看到有 ValidatingWebhookConfiguration，將資源內容傳送給指定的 Webhook 服務，Webhook 回覆： 「允許 (Allow)」或「拒絕 (Deny)」
    ✨ Persistence：存入 etcd
    ```

    - 常見的實際應用場景:
      - 標籤強制檢查：規定所有 Pod 必須帶有特定標籤(env: prod)否則拒絕建立
      - 安全性檢查：拒絕所有嘗試以 root 身分執行的容器
      - 資源配額限制：檢查 Pod 是否設定了 limits 和 requests，沒寫就拒絕建立
      - 映像檔來源檢查：只准許從公司內部的 gcr.io/my-company/ 下載 Image，禁止使用 Docker Hub

### [CRD SleepInfo 設定](https://kube-green.dev/docs/configuration/)

📌 kube-green 內建開關，會記得服務的原始的狀態，如果原本服務是手動關閉，喚醒時不會誤打開

- suspendCronJobs
- suspendDeployments
- suspendStatefulSets

📌  使用 patch 手動改寫：這是「永久性」或「靜態」的修改，一旦這個 Patch 生效，你的服務就會永遠處於暫停狀態，除非你手動移除這個 Patch

```yaml
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: example
spec:
  weekdays: "*"
  sleepAt: "20:00"
  wakeUpAt: "08:00" ⭐ Sleep without wake up 時可以省略
  timeZone: "Asia/Taipei"
  suspendCronJobs: true ⭐ 是否關閉 CronJobs
  suspendDeployments: false ⭐ 是否關閉 Deployments
  suspendStatefulSets: false ⭐ 是否關閉 StatefulSets
  excludeRef:
    # Exclude resources
    - apiVersion: "batch/v1"
      kind:       CronJob
      name:       do-not-suspend
    - apiVersion: "apps/v1"
      kind:       Deployment
      name:       api-gateway
    # Exclude with labels
    - matchLabels:
        kube-green.dev/exclude: true
  includeRef:
    # Include with labels
    - matchLabels:
        kube-green.dev/include: true
    # Custom patches
  patches:
    - target:
        group: apps
        kind: ReplicaSet
      patch: |-
        - path: /spec/replicas
          op: add
          value: 0
    - target:
        group: batch
        kind: CronJob
      patch: |-
        - path: /spec/suspend
          op: replace
          value: true
```

## [descheduler](https://github.com/kubernetes-sigs/descheduler)
