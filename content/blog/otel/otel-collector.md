+++
date = "2025-09-10T13:30:00+08:00"
draft = false
title = "可觀測性"
description = ""
tags = ["observability"]
categories = ["otel"]
+++

## OpenTelemetry Collector

### apps 用途說明

#### otel-agent (daemonset)

負責採集節點上面的 log & metric (採集服務資訊)

- receiver
  - [receivercreator](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/receivercreator)
- processor
- exporter
- extension
  - [k8s_observer](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/observer/k8sobserver)

#### otel-cluster-agent (deployment)

負責採集叢集 metric (採集系統資訊，用 daemonset 可能重複送)

#### otel-gateway (deployment)

匯總叢集內的 otel-agent 與 otel-cluster-agent 資料並送到儲存後端 (評估可有可無，若有統一處理的動作才有效益 [e.g. 統一加 tag])

#### collector (deployment)

接收 OpenTelemetry SDK 所送出的資料 (需要在程式使用 otel libery，傳送 log、metric、trace，目前規劃主要針對 trace)

#### Otelcol Gateway & Agent

- Otelcol Gateway：收集所有專案的 otel 資料傳送至 eck
- Otelcol Agent：每個 gcp 專案會建立一個，收集專案中服務的 otel 資料傳送至 Otelcol Gateway
- 想使用 otel 的服務，需要調整程式，然後加上 env:

```text
extraEnvs:
  - name: OTEL_SERVICE_NAME
    value: odin
  - name: OTEL_RESOURCE_ATTRIBUTES
    value: >-
      env=dev,
      dept=pdbm,
      product=bbin
  - name: OTEL_EXPORTER_OTLP_PROTOCOL
    value: grpc
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: http://collector.opentelemetry:4317
```

#### Otelcol 配置

- collector = receivers + processors + exporters
  - receivers: 從外部系統收資料（metrics / logs / traces）
  - processors: 在 pipeline 中對資料做處理（e.g. 篩選、轉換、打標籤、聚合）
  - exporters: 把資料送到外部目的地（e.g. Datadog、OTLP、S3）
- extensions：擴充 collector 的功能
- connectors：擴充 pipeline 的功能 [中繼處理或橋接的元件]
  - datadog/connector: 把資料轉給 Datadog。
  - forward/datadog: 單純做轉發
  - 內部 exporter + receiver
    - 讓資料從一個 pipeline 流向另一個 pipeline

    ```text
    pipelines:
      # Logs pipelines -> 服務透過 otel 傳送到 collector，collector 再傳到 datadog
      logs:
        receivers: [otlp]
        processors: [memory_limiter, k8sattributes, resource, batch]
        exporters: [forward/datadog]

      logs/datadog:
        receivers: [forward/datadog]
        processors: [memory_limiter, batch/datadog]
        exporters: [datadog]
    ```

    - 做 failover / forward

    ```text
    pipelines:
      traces:
        receivers: [otlp]
        processors: [memory_limiter, k8sattributes, resource, batch]
        exporters: [failover/traces, datadog/connector]
      traces/nop:
        receivers: [failover/traces]
        exporters: [nop]
    ```

- ${env:MY_POD_IP} -> otelcol 底層有處理，才能這樣設定取 env 的值

```text
# exporters、processors、receivers [定義]
## helmfile/common/otel-collector -> Otelcol Agent
## helmfile/pd/observability/apps/otel-collector -> Otelcol Gateway
config:
  exporters:
    datadog:
      api:
        ...
      metrics:
        resource_attributes_as_tags: true
    otlp/elastic-apm: --> eck 服務
      balancer_name: round_robin
      endpoint: dns:///eck-apm-server-apm-http:8200
      ...

  extensions:
    health_check:
      endpoint: ${env:MY_POD_IP}:13133

  processors: -> 效能優化及資料處理
    batch: {}
    batch/datadog:
      # See https://docs.datadoghq.com/opentelemetry/setup/collector_exporter/#batch-processor-configuration
      send_batch_max_size: 100
      send_batch_size: 10
      timeout: 10s
    memory_limiter:
      check_interval: 5s
      limit_percentage: 80
      spike_limit_percentage: 25
    k8sattributes: {} -> 可以設定使用 k8s 上的 tag
    resource: {}
    transform/elastic-apm:
      error_mode: ignore
      log_statements: &statements
        - conditions:
            - resource.attributes["product"] != nil and resource.attributes["env"] != nil
          statements:
            - set(resource.attributes["deployment.environment.name"], Concat([resource.attributes["product"], resource.attributes["env"]], " "))
        ...

  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: ${env:MY_POD_IP}:4317
          ...
        http:
          endpoint: ${env:MY_POD_IP}:4318
          ...
    otelarrow: -> gateway 使用，會壓縮
      protocols:
        grpc:
          endpoint: ${env:MY_POD_IP}:4319
          ...

    prometheus:
      ...
```

```text
# pipeline [使用]
# common/otel-collector -> Otelcol Agent
  ...
    extensions: [zpages, health_check] -> zpages 可以看 collector 設定
    pipelines:
      # Logs pipelines -> 服務透過 otel 傳送到 collector，collector 再傳到 datadog
      logs:
        receivers: [otlp]
        processors: [memory_limiter, k8sattributes, resource, batch]
        exporters: [forward/datadog]

      # Metrics pipelines -> 服務透過 otel / prometheus 傳送到 collector，collector 再傳到 datadog
      metrics:
        receivers: [otlp, prometheus]
        processors: [memory_limiter, k8sattributes, resource, batch]
        exporters: [forward/datadog]

      # Traces pipelines
      traces:
        receivers: [otlp]
        processors: [memory_limiter, k8sattributes, resource, batch]
        exporters: [failover/traces, datadog/connector]
      traces/main:
        receivers: [failover/traces]
        processors: [memory_limiter, filter/traces, probabilistic_sampler, batch]
        exporters: [otelarrow/gateway]
      traces/nop:
        receivers: [failover/traces]
        exporters: [nop] -> failover 把資料丟掉，防止累積大量資料把 collector 用爆

      # Datadog pipelines
      logs/datadog:
        receivers: [forward/datadog]
        processors: [memory_limiter, batch/datadog]
        exporters: [datadog]
      metrics/datadog:
        receivers: [forward/datadog, datadog/connector]
        processors: [memory_limiter, batch/datadog]
        exporters: [datadog]

# helmfile/pd/observability/apps/otel-collector -> Otelcol Gateway
service:
    ...
    extensions: [health_check]
    pipelines:
      # Telemetry pipelines
      metrics/telemetry:
        receivers: [prometheus]
        processors: [memory_limiter, k8sattributes, resource]
        exporters: [forward/datadog]

      # Datadog pipelines
      metrics/datadog:
        receivers: [forward/datadog]
        processors: [memory_limiter, batch/datadog]
        exporters: [datadog]

      # Gateway pipelines -> 服務透過 otel / otelarrow 傳送到 collector，collector 再傳到 eck
      logs:
        receivers: [otlp, otelarrow]
        processors: [memory_limiter, transform/elastic-apm, batch]
        exporters: [otlp/elastic-apm]
      metrics:
        receivers: [otlp, otelarrow]
        processors: [memory_limiter, transform/elastic-apm, batch]
        exporters: [otlp/elastic-apm]
      traces:
        receivers: [otlp, otelarrow]
        processors: [memory_limiter, transform/elastic-apm, batch]
        exporters: [otlp/elastic-apm]
```

## metric scope

- 看 metric 是從哪邊來的
