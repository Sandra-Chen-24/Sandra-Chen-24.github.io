+++
date = "2025-09-16T15:30:00+08:00"
draft = false
title = "還沒想到分類"
description = ""
tags = ["basic"]
categories = ["common"]
+++

```text
# $http_referer 去匹配正則規則 "~^https://(?<domain>[^/]+)"，取出 https:// 後面第一段不含 / 的字串存進 $domain
map $http_referer $effective_host {
  default $host;
  "~^https://(?<domain>[^/]+)" $domain;
}
```
