+++
date = "2025-10-31T15:30:00+08:00"
draft = false
title = "gateway api vs api gateway"
description = ""
tags = ["basic"]
categories = ["debug"]
+++

```text
nc -zv -w 3 122.117.26.93 3390

nc (Netcat):可以建立 TCP/UDP 連線、監聽埠口、甚至傳輸檔案
-z (Zero-I/O mode):只進行連線測試，不進行任何資料輸入輸出
-v (Verbose)：詳細輸出模式。
-w (Timeout)：設定逾時（Timeout）時間為 3 秒
```

nc -zv -w 3 ${IP} ${PORT}