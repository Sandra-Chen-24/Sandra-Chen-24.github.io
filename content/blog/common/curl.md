
+++
date = "2025-09-19T15:30:00+08:00"
draft = false
title = "curl 的歷程"
description = ""
tags = ["basic"]
categories = ["common"]
+++

## 使用 HTTP 跟 HTTPS 差別

```yaml
geo.conf: |
  geo $allowed_ip_geo {
    default 0;
    34.1.1.1 @aaa;
    130.1.1.1 @bbb;
  }

  map $allowed_ip_geo$host $valid_request {
    default 0;
    "@bbbhall.bbb999.com" 1;
    "@aaahall.aaa888.com" 1;
  }
```

```text
# hall.aaa888.com 有解析，hall.bbb999.com 沒有解析
⭐ ## 有解析的 host 使用 https 跟 http 差別
[hall.aaa888.com 應該使用 34.1.1.1 入口，想模擬使用 130.1.1.1 被阻擋]
💡 ### http
curl http://130.1.1.1 -H 'host: hall.aaa888.com' -vvv -kL
< HTTP/1.1 301 Moved Permanently
< Location: https://hall.aaa888.com:443/
* Issue another request to this URL: 'https://hall.aaa888.com:443/'
< HTTP/1.1 200 OK
* Connection #1 to host hall.aaa888.com left intact

💡 ### https
curl https://130.1.1.1 -H 'host: hall.aaa888.com' -vvv -kL
< HTTP/1.1 403 Forbidden
* Connection #0 to host 130.1.1.1 left intact

📌 -> http 會遇到 301 然後用 host 的網址是解析轉導，因為有設定 80 強轉 443
✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨
⭐ ## 沒解析的 host 使用 https 跟 http 差別
🔍🔍🔍 設定正確 IP，跟有解析情境同
[本地設定：130.1.1.1 hall.bbb999.com]
💡 ### http
curl http://34.1.1.1 -H 'host: hall.bbb999.com' -vvv -kL
< HTTP/1.1 301 Moved Permanently
< Location: https://hall.bbb999.com:443/
* Issue another request to this URL: 'https://hall.bbb999.com:443/'
< HTTP/1.1 200 OK
* Connection #1 to host hall.bbb999.com left intact

💡 ### https
curl https://34.1.1.1 -H 'host: hall.bbb999.com' -vvv -kL
< HTTP/1.1 403 Forbidden
* Connection #0 to host 34.1.1.1 left intact

🔍🔍🔍 設定錯誤確 IP
[本地設定：34.1.1.1 hall.bbb999.com]
💡 ### http
curl http://34.1.1.1 -H 'host: hall.bbb999.com' -vvv -kL
< HTTP/1.1 301 Moved Permanently
< Location: https://hall.bbb999.com:443/
* Issue another request to this URL: 'https://hall.bbb999.com:443/'
< HTTP/1.1 403 Forbidden

💡 ### https
curl https://34.1.1.1 -H 'host: hall.bbb999.com' -vvv -kL
< HTTP/1.1 403 Forbidden
* Connection #0 to host 34.1.1.1 left intact
-> 等同於 curl https://hall.bbb999.com -k
```
