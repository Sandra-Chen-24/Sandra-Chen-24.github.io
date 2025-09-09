+++
date = "2025-09-09T15:30:00+08:00"
draft = false
title = "機器類型"
description = ""
tags = ["basic"]
categories = ["aws"]
+++

[機器類型及費用](https://instances.vantage.sh/)

## 機器類型

- n:AMD (x86_64)
- g:AWS Graviton (arm64)：image 需要支援 arm 且調整設定
    -> ami_type：要使用 AL2023_ARM_64_STANDARD，預設是 AL2023_x86_64_STANDARD

    ```text
    gitlab-runners-arm = {
      instance_types = ["m6g.medium"]
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      capacity_type  = "SPOT"
      ami_type        = "AL2023_ARM_64_STANDARD"

      labels = {
        "service" = "gitlab-runner-arm"
      }
    }
    ```

    -> gitlab-runner 需要多帶 helper_image = "gitlab/gitlab-runner-helper:arm64-latest"

    ```text
    config: |
      [[runners]]
        [runners.kubernetes]
          namespace = "gitlab"
          image = "ubuntu:20.04"
          helper_image = "gitlab/gitlab-runner-helper:arm64-latest"
          privileged = true
    ```

    -> CICD 裡面，如果在 build 時，有用到以下指令來安裝 kubectl，需要確認是否是改為 arm64

    ```text
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl
    ```

- 其他 ：Intel (x86_64)
