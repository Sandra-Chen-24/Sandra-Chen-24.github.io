+++
date = "2025-12-16T10:30:00+08:00"
draft = false
title = "Custom Compute Class"
description = ""
tags = ["gke"]
categories = ["gcp"]
+++

## ComputeClass

- 使用情境
  - 使用預約資源
  - 加速 node 縮減
  - Enable NAP per class
    - GKE 1.33.3-gke.1136000 以上版本:nodePoolAutoCreation
    - GKE 1.33.3-gke.1136000 以下版本:啟用叢集層級的節點自動佈建功能 [Node auto-provisioning]
- 在工作負載資訊清單中選取 ComputeClass，方法是使用 cloud.google.com/compute-class 標籤
  - 內建的 ComputeClass：在 Standard 叢集中執行 Autopilot 模式工作負載 [適用於 1.34.1-gke.1829001 以上版本]
    - autopilot
    - autopilot-spot
  - 設定自訂 Autopilot ComputeClass

    ```yaml
    apiVersion: cloud.google.com/v1
    kind: ComputeClass
    metadata:
      name: n4-class
    spec:
      autopilot:
        enabled: true
      priorities:
      - machineFamily: n4
        spot: true
        minCores: 16
      - machineFamily: n4
        spot: true
      - machineFamily: n4
        spot: false
      activeMigration:
        optimizeRulePriority: true
    ```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: helloweb
  labels:
    app: hello
spec:
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      nodeSelector:
        # Replace with the name of a compute class
        cloud.google.com/compute-class: COMPUTE_CLASS
      containers:
      - name: hello-app
        image: us-docker.pkg.dev/google-samples/containers/gke/hello-app:1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: "250m"
            memory: "1Gi"
```

```yaml
apiVersion: autoscaling.gke.io/v1
kind: ComputeClass
metadata:
  name: my-class
spec:
  activeMigration:
    optimizeRulePriority: true
  nodePoolAutoCreation:
    enabled: true
  priorities:
  - machineFamily: n4
    spot: true
  - machineFamily: n2d
spot: true
    minCores: 16
  - machineType: n4-standard-16
  - spot: false
  autoscalingPolicy:
    consolidationDelayMinutes: 5
```
[Custom Compute Class](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes?hl=zh-tw#how-custom)

### activeMigration

- 選用自動調度資源功能，可自動以新節點取代現有節點。節點會根據特定條件替換，具體取決於遷移類型，GKE 會建立新節點，然後排空並刪除舊節點
  - 🚫 遷移作業不會遷移儲存在永久儲存空間中的資料，例如 Compute Engine 永久磁碟。為盡量降低資料遺失風險，請勿在有狀態工作負載使用的 ComputeClass 中啟用主動遷移功能
  - 🚫 如果節點無法移除，進行中的遷移作業不會取代這些節點。舉例來說，如果主動遷移會違反 --min-nodes 節點集區設定，就不會取代節點
  - 🚫 為避免重要工作負載中斷，遷移作業不會移動下列 Pod：
    - 設定 PodDisruptionBudget 的 Pod，如果移動作業會超出 PodDisruptionBudget。
    - 具有 cluster-autoscaler.kubernetes.io/safe-to-evict: "false" 註解的 Pod
  - 支援的有效遷移類型如下：
    - optimizeRulePriority：以優先順序清單中較高的節點，取代 ComputeClass 優先順序清單中較低的節點
    - ensureAllDaemonSetPodsRunning：以較大的節點取代具有無法排程的 DaemonSet Pod 的節點，這些節點能夠執行所有必要的 DaemonSet Pod

### reservations

- Cloud 區域的硬體可用性，則可以在自訂 ComputeClass 中設定每個備援優先順序，讓 GKE 在建立新節點時使用預留資源，⭐ 適用於 GKE 1.31.1-gke.2105000 以上版本
  - 必須使用節點集區自動建立功能，GKE 才能使用預留資源建立新節點
  - 只有在定義 machineType 或 machineFamily 時，才能使用非 TPU 預留項目
  - 設定本機 SSD 的 ComputeClass 必須使用 machineType 優先順序規則，而非 machineFamily，必須明確包含 localSSDCount: 欄位

### autoscalingPolicy

- 微調觸發節點移除和工作負載整併的資源使用率不足門檻
- 可以微調下列參數：
  - consolidationDelayMinutes：GKE 移除使用率不足的節點前，等待的分鐘數
  - consolidationThreshold：CPU 和記憶體的使用率門檻，以節點可用資源的百分比表示。只有在資源使用率低於這個門檻時，GKE 才會考慮移除節點
