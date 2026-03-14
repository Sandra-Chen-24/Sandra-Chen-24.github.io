+++
date = "2026-02-04T23:37:57+08:00"
draft = false
title = "minio 建置"
description = ""
tags = ["minio"]
categories = ["storage"]
+++

## [install](https://github.com/minio/minio)

```text
# 找密碼
cat /etc/default/minio

# 在 VM 安裝 MinIO CLI
# 1. 下載執行檔
wget https://dl.min.io/client/mc/release/linux-amd64/mc

# 2. 賦予執行權限
chmod +x mc

# 3. 搬移到系統路徑，方便隨時呼叫
sudo mv mc /usr/local/bin/mc

# 4. 驗證安裝
mc --version

# 透過 MinIO 控制台產生 Access Key 和 Secret Key
-> 點擊右上角的 「Create access key」

# 設定連線資訊 (Alias) [需要告訴 mc 你的 MinIO 伺服器在哪裡]
# Console Port (預設 9001)：這是給 「瀏覽器介面」 用的，讓你用滑鼠點選管理
# API Port (預設 9000)：這是給 「程式碼 (SDK)」 或 「mc 指令」 用的
mc alias set [別名] [伺服器網址] [AccessKey] [SecretKey]
-> mc alias set planb-minio http://127.0.0.1:9000 [AccessKey] [SecretKey]

# 常用指令
列出所有 Bucket: mc ls planb-minio
建立新 Bucket: mc mb planb-minio/test-bucket
上傳檔案: mc cp local-file.txt planb-minio/test-bucket/
查看檔案內容: mc cat planb-minio/test-bucket/file.txt
同步目錄: mc mirror ./local-folder planb-minio/test-bucket/
```
