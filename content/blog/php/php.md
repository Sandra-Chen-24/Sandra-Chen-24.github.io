+++
date = "2026-03-09T11:30:00+08:00"
draft = false
title = "php 版本設定"
description = ""
tags = ["php"]
categories = ["php"]
+++

## module 跟版本確認

```text
# module
php -m | grep -E "redis|mongodb|grpc|opentelemetry"

# module 版本
php -r '
  $exts = ["redis", "mongodb", "grpc", "opentelemetry"];
  foreach ($exts as $ext) {
      if (extension_loaded($ext)) {
          $version = phpversion($ext);
          echo str_pad($ext, 15) . ": $version\n";
      } else {
          echo str_pad($ext, 15) . ": Not Installed\n";
      }
  }
'
```
