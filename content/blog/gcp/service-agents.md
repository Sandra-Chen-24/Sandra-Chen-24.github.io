+++
date = "2025-09-16T15:30:00+08:00"
draft = false
title = "權限相關"
description = ""
tags = ["iam"]
categories = ["gcp"]
+++

[service-agents](https://cloud.google.com/iam/docs/service-agents)

```text
# 由 Google 自動建立的 Google-managed service accounts，不會出現在「IAM → Service Accounts」清單中
例如：
Logging → service-PROJECT_NUMBER@gcp-sa-logging.iam.gserviceaccount.com
Monitoring → service-PROJECT_NUMBER@gcp-sa-monitoring.iam.gserviceaccount.com
Pub/Sub → service-PROJECT_NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com

# 查詢角色設定
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --format="table(bindings.role, bindings.members)" \
  --filter="bindings.members:service-${PROJECT_NUMBER}@gcp-sa-logging.iam.gserviceaccount.com"
```
