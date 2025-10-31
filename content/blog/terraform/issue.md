+++
date = "2025-10-30T10:54:57+08:00"
draft = false
title = "Terraform issue"
description = "Terraform issue"
tags = ["issue"]
categories = ["terraform"]
+++

## google terraform provider bug

- 使用 terraform 設定 kubelet_config 區塊，預設會把 cpuCfsQuota 設定為 false，跟 GCP API 相反，GCP API 預設設定為 true
-> This issue is fixed in the "7.6.0" terraform google provider version
[v7.6.0](https://github.com/hashicorp/terraform-provider-google/releases/tag/v7.6.0)
