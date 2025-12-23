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

📌 kube-green 內建開關，會記得服務的原始的狀態，如果原本服務是手動關閉，喚醒時不會誤打開 [sleepAt 關 pod，wakeUpAt 開 pod]

- suspendCronJobs
- suspendDeployments
- suspendStatefulSets
-> ⭐ 預設關閉這兩個資源類型的服務 deployment and statefulset

```text
✨ To sleep the Deployment and StatefulSet resources, replicas are set to 0.
✨ To wake up, the number of replicas is set to the number of replicas before the sleep

✨ To sleep the CronJob resources, they are set as suspended.
✨ To wake up, the suspend field is restored
```

📌  使用 patch 改寫： [布版當下關 pod，wakeUpAt 開 pod]
📌  kind: SleepInfo 資源的 namespace 要跟要關閉的服務相同

[docs](https://kube-green.dev/docs/apireference_v1alpha1/)

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
    # Exclude resources [設定多組測試正常]
    - apiVersion: "batch/v1"
      kind:       CronJob
      name:       do-not-suspend
    - apiVersion: "apps/v1"
      kind:       Deployment
      name:       api-gateway
    # Exclude with labels
    - matchLabels:
        kube-green.dev/exclude: "true"
  includeRef:
    # Include resources [⚠️ 設定一個以上條件不會作動]
    - apiVersion: "apps/v1"
      kind:       Deployment
      name:       api-gateway
    # Include with labels
    - matchLabels:
        kube-green.dev/include: "true"
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

### 測試

```yaml
# 布版當下關 pod，wakeUpAt 開 pod
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: example
spec:
  weekdays: "*"
  sleepAt: "17:42"
  wakeUpAt: "17:45"
  timeZone: "Asia/Taipei"
  suspendCronJobs: false
  suspendDeployments: false
  suspendStatefulSets: false
  includeRef:
    - apiVersion: "apps/v1"
      kind: Deployment
      name: api-hex
  patches:
    - target:
        group: apps
        kind: Deployment
      patch: |-
        - path: /spec/replicas
          op: add
          value: 0

# sleepAt 關 pod，wakeUpAt 開 pod
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: example
spec:
  weekdays: "*"
  sleepAt: "17:42"
  wakeUpAt: "17:45"
  timeZone: "Asia/Taipei"
  suspendCronJobs: false
  suspendDeployments: true
  suspendStatefulSets: false
  includeRef:
    - apiVersion: "apps/v1"
      kind: Deployment
      name: api-hex
  patches:
    - target:
        group: apps
        kind: Deployment
      patch: |-
        - path: /spec/replicas
          op: add
          value: 0

# sleepAt 關 pod，wakeUpAt 開 pod
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: example
spec:
  weekdays: "*"
  sleepAt: "17:42"
  wakeUpAt: "17:45"
  timeZone: "Asia/Taipei"
  suspendCronJobs: false
  suspendDeployments: true
  suspendStatefulSets: false
  includeRef:
    - apiVersion: "apps/v1"
      kind: Deployment
      name: api-hex

# sleepAt 調升 pod 數量，wakeUpAt 調回原本 pod 數量
apiVersion: kube-green.com/v1alpha1
kind: SleepInfo
metadata:
  name: example
spec:
  weekdays: "*"
  sleepAt: "14:15"
  wakeUpAt: "14:18"
  timeZone: "Asia/Taipei"
  suspendCronJobs: false
  suspendDeployments: true
  suspendStatefulSets: false
  patches:
    - target:
        group: apps
        kind: Deployment
      patch: |-
        - path: /spec/replicas
          op: add
          value: 3
```

### Manual management of certificates

[Generate Self-Signed Certificates step by step](https://kube-green.dev/docs/advanced/webhook-cert-management/#without-cert-manager)

- openssl.conf

```text
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
CN = kube-green-webhook-service.kube-green.svc.cluster.local

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kube-green-webhook-service
DNS.2 = kube-green-webhook-service.kube-green
DNS.3 = kube-green-webhook-service.kube-green.svc
DNS.4 = kube-green-webhook-service.kube-green.svc.cluster.local
```

- And then run the following commands:

```text
# Generate CA private key
openssl genpkey -algorithm RSA -out ca.key

# Generate CA certificate for 100 years
openssl req -new -nodes -x509 -key ca.key -out ca.crt -days 36500 -subj "/CN=The CA"

# Generate private key
openssl genpkey -algorithm RSA -out tls.key

# Generate certificate signing request
openssl req -new -key tls.key -out tls.csr -config openssl.conf

# Generate certificate signed with the CA
openssl x509 -req -in tls.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt -days 365 -extfile openssl.conf -extensions req_ext
```

- After creating the certificates, you can create the secret with the following command:

```text
kubectl create secret tls webhook-server-cert --cert=./tls.crt --key=./tls.key
```

Once generated, you can create the kube-green manifests (commenting out the [CERT-MANAGER] part), create the base64 of the ca.crt file and patch the webhook configuration with the new caBundle.

```text
cat ca.crt | base64
```

```yaml
webhooks:
  - name: vsleepinfo.kb.io
    clientConfig:
      caBundle: <CA_BUNDLE>
```

[helmfile-advanced-features](https://helmfile.readthedocs.io/en/latest/advanced-features/)
-> 調整 chart

```yaml
releases:
  - <<: *kube-green
    name: kube-green
    strategicMergePatches:
      - apiVersion: admissionregistration.k8s.io/v1
        kind: ValidatingWebhookConfiguration
        metadata:
          name: kube-green-validating-webhook-configuration
        webhooks:
          - name: vsleepinfo.kb.io
            clientConfig:
              caBundle: <CA_BUNDLE>
```

```yaml
# 跟 strategicMergePatches 相等寫法
## jsonPatches
    jsonPatches:
      - target:
          group: admissionregistration.k8s.io
          version: v1
          kind: ValidatingWebhookConfiguration
          name: kube-green-validating-webhook-configuration
        patch:
          - op: replace
            path: /webhooks/0/clientConfig/caBundle
            value: <CA_BUNDLE>
## transformers
    transformers:
      - apiVersion: builtin
        kind: PatchTransformer
        metadata:
          name: patch-ca-bundle
        patch: |-
          - op: replace
            path: /webhooks/0/clientConfig/caBundle
            value: <CA_BUNDLE>
        target:
          kind: ValidatingWebhookConfiguration
          name: kube-green-validating-webhook-configuration
```

## [descheduler](https://github.com/kubernetes-sigs/descheduler)
