+++
date = "2025-12-16T10:30:00+08:00"
draft = false
title = "Custom Compute Class"
description = ""
tags = ["gke","cost"]
categories = ["gcp"]
+++

[Practical Guide to Kueue and Custom Compute Classes](https://medium.com/google-cloud/practical-guide-to-kueue-and-custom-compute-classes-85a3fe287487)
[Compute Flexible CRDs](https://docs.cloud.google.com/compute/docs/instances/committed-use-discounts-overview?hl=zh-tw#spend_based)
[GKE Custom Compute Class Examples](https://github.com/vszal/gke-custom-compute-class-examples)

## [Custom Compute Class](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes?hl=zh-tw#how-custom)

- 🚫 限制 ComputeClass 的名稱開頭不得為 gke 或 autopilot
- 使用預約資源 [reservations](https://docs.cloud.google.com/compute/docs/instances/reservations-overview?hl=zh-tw)
- 定義自動調度資源的門檻和參數，以便移除未充分利用的節點 [autoscalingPolicy]
- 自動替換為更適合的節點設定 [activeMigration]
- Enable NAP (Node auto-provisioning) per class
  - GKE 1.33.3-gke.1136000 以上版本 [nodePoolAutoCreation]
  - GKE 1.33.3-gke.1136000 以下版本:啟用叢集層級的節點自動佈建功能 [Node auto-provisioning]
- 內建的 ComputeClass：在 Standard 叢集中執行 Autopilot 模式工作負載 [適用於 1.34.1-gke.1829001 以上版本](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-built-in-compute-classes?hl=zh-tw)
  - autopilot
  - autopilot-spot
  - 建立自訂 Autopilot ComputeClass

  ```yaml
  spec:
    autopilot:
      enabled: true
  ```

- 在工作負載資訊清單中選取 ComputeClass，方法是使用 cloud.google.com/compute-class 標籤

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      nodeSelector:
        # Replace with the name of a compute class
        cloud.google.com/compute-class: COMPUTE_CLASS
```

- 自動產生的 node 前綴會是 nap- (for Node Auto-Provisioning)

```yaml
apiVersion: cloud.google.com/v1
kind: ComputeClass
metadata:
  name: {{ .name }}
spec:
  activeMigration:
    optimizeRulePriority: true
  nodePoolAutoCreation:
    enabled: true
  priorities:
    - nodepools:
      - arm-default-pool
    - machineType: c4a-highmem-4
      spot: true
    - machineType: n2-highmem-4
      spot: true
    - machineType: c4a-highmem-4
    - machineType: n2-highmem-4
  autoscalingPolicy:
    consolidationDelayMinutes: 5
```

### [priorities](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes?hl=zh-tw#priority-rules)

- machineFamily

```yaml
priorities:
- machineFamily: n4
  spot: true
  minCores: 16
  minMemoryGb: 64
  storage:
    bootDiskKMSKey: projects/example/locations/us-central1/keyRings/example/cryptoKeys/key-1
    secondaryBootDisks:
    - diskImageName: pytorch-mnist
      project: k8s-staging-jobset
```

- machineType

```yaml
priorities:
- machineType: n4-standard-32
  spot: true
  storage:
    bootDiskType: pd-balanced
    bootDiskSize: 250
    localSSDCount: 2
    bootDiskKMSKey: projects/example/locations/us-central1/keyRings/example/cryptoKeys/key-1
```

- [nodepools](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes?hl=zh-tw#manual-node-pools)
  - 🚫 這個欄位僅支援 GKE Standard 模式

- [priorityDefaults](https://docs.cloud.google.com/kubernetes-engine/docs/reference/crds/computeclass#priorityDefaults)
  - GKE 1.32.1-gke.1729000 以上版本

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

### [reservations](https://docs.cloud.google.com/compute/docs/instances/reservations-overview?hl=zh-tw)

- Cloud 區域的硬體可用性，則可以在自訂 ComputeClass 中設定每個備援優先順序，讓 GKE 在建立新節點時使用預留資源，⭐ 適用於 GKE 1.31.1-gke.2105000 以上版本
  - 必須使用節點集區自動建立功能，GKE 才能使用預留資源建立新節點
  - 只有在定義 machineType 或 machineFamily 時，才能使用非 TPU 預留項目
  - 設定本機 SSD 的 ComputeClass 必須使用 machineType 優先順序規則，而非 machineFamily，必須明確包含 localSSDCount: 欄位

```yaml
apiVersion: cloud.google.com/v1
kind: ComputeClass
metadata:
  name: shared-specific-reservations
spec:
  nodePoolAutoCreation:
    enabled: true
  priorities:
  - machineFamily: n4
    reservations:
      specific:
      - name: n4-shared-reservation
        project: reservation-project
      affinity: Specific ⭐ 必須必須為 Specific
  - machineType: a3-highgpu-1g
    storage:
      localSSDCount: 2
    gpu:
      type: nvidia-h100-80gb
      count: 1
    reservations:
      affinity: AnyBestEffort ⭐ 任何相符的預訂
  - machineFamily: n4
    spot: true
  - machineFamily: n4
  whenUnsatisfiable: DoNotScaleUp
```

### autoscalingPolicy

- 微調觸發節點移除和工作負載整併的資源使用率不足門檻
- 可以微調下列參數：
  - consolidationDelayMinutes：GKE 移除使用率不足的節點前，等待的分鐘數
  - consolidationThreshold：CPU 和記憶體的使用率門檻，以節點可用資源的百分比表示。只有在資源使用率低於這個門檻時，GKE 才會考慮移除節點

### whenUnsatisfiable

- ScaleUpAnyway: ComputeClass 優先順序中沒有的機器系列，會觸發節點建立作業，GKE 1.33 之前的預設值
- DoNotScaleUp: ComputeClass 優先順序中沒有的機器系列，不會觸發節點建立作業，GKE 1.33 以上版本的預設值

### nodePoolGroup

- 將多個節點集區分組為單一邏輯單元，稱為「集合」。這個分組功能可讓您將共用設定套用至多個節點集區

```yaml
spec:
  nodePoolGroup:
    name: my-tpu-collection
```

### [nodePoolConfig](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/about-custom-compute-classes?hl=zh-tw#node_pool_configuration)

## [預設 ComputeClass](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/run-pods-default-compute-classes?hl=zh-tw)

- 可以將 GKE 叢集或特定命名空間設定為具有預設 ComputeClass
  - 將 ComputeClass 設為叢集層級的預設值，叢集必須執行 GKE 1.33.1-gke.1744000 以上版本

  ```yaml
  apiVersion: cloud.google.com/v1
  kind: ComputeClass
  metadata:
    name: default
  spec:
    priorities:
    - machineFamily: n4
    - machineFamily: n2
    whenUnsatisfiable: ScaleUpAnyway
    nodePoolAutoCreation:
      enabled: true
  ```

  ```text
  gcloud container clusters update CLUSTER_NAME \
      --location=CONTROL_PLANE_LOCATION \
      --enable-default-compute-class
  ```

  - 將 ComputeClass 設為命名空間層級的預設值，但僅適用於非 DaemonSet Pod，叢集必須執行 GKE 1.33.1-gke.1788000 以上版本

  ```text
  kubectl label namespaces NAMESPACE_NAME \
    cloud.google.com/default-compute-class=COMPUTECLASS_NAME
  ```

## [ResourceFlavor](https://kueue.sigs.k8s.io/zh-cn/docs/concepts/resource_flavor/)

- 當不再只是單純地想讓 Pod 「有地方跑」，而是想要精細化管理不同類型的計算資源（如 GPU 型號、Spot 執行個體、不同 CPU 架構）時，就會需要 ResourceFlavor
  - Kueue + ResourceFlavor： 在任務排隊階段就先檢查想用的資源，如果配額滿了，任務會直接在隊列中等待，而不是去跟 K8s 調度器硬碰硬，減少了叢集壓力並提高了公平性
    - 針對 Spot 資源與 On-Demand 資源的 Kueue 配置範例

    ```yaml
    # Spot 資源
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ResourceFlavor
    metadata:
      name: spot-flavor
    spec:
      nodeLabels:
        cloud.google.com/gke-spot: "true" # 確保任務只會跑在標記為 Spot 的節點上
    ---
    # On-Demand 資源
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ResourceFlavor
    metadata:
      name: on-demand-flavor
    spec:
      nodeLabels:
        cloud.google.com/gke-spot: "false" # 確保任務跑在一般節點上
    ---
    # 定義 ClusterQueue (全域配額管理)
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: ClusterQueue
    metadata:
      name: combined-cluster-queue
    spec:
      namespaceSelector: {} # 允許所有 namespace 使用
      resourceGroups:
      - coveredResources: ["cpu", "memory"]
        flavors:
        - name: spot-flavor  # 放在第一個，代表優先使用
          resources:
          - name: "cpu"
            nominalQuota: 100 # Spot 總共給 100 核心
          - name: "memory"
            nominalQuota: 400Gi
        - name: on-demand-flavor # 放在第二個，作為備援
          resources:
          - name: "cpu"
            nominalQuota: 50  # On-Demand 較貴，只給 50 核心
          - name: "memory"
            nominalQuota: 200Gi
    ---
    # 使用(LocalQueue)
    apiVersion: kueue.x-k8s.io/v1beta1
    kind: LocalQueue
    metadata:
      name: team-a-queue
      namespace: team-a
    spec:
      clusterQueue: combined-cluster-queue
    ```
