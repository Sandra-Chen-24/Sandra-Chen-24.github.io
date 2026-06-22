+++
date = "2026-05-22T10:00:00+08:00"
draft = false
title = "nginx 長連線"
description = ""
tags = ["效能"]
categories = ["nginx"]
+++

Nginx 預設的隱藏行為：當使用 proxy_pass 把請求轉發給後端（例如你的 Go, Node.js 或 Java 服務）時，會將 HTTP 協定降級為 HTTP/1.0，並且會隱含地把 Connection 標頭設定為 close
-> 在 Nginx 設定了 proxy_set_header Connection "";，把預設要發送給後端的 Connection: close 標頭直接抹除（不發送），當後端服務收到一個 HTTP/1.1 的請求，且裡面沒有 Connection: close 標頭時，後端服務就會預設啟用 Keep-Alive，允許這個 TCP 連線繼續留著給下一個請求使用 [必須搭配 proxy_http_version 與 keepalive 一起使用]

```text
upstream my_backend {
    server 127.0.0.1:8080;
    
    # 1. 💡 關鍵：設定 Nginx 與後端連線池的「最大空閒長連線數」
    keepalive 32; 
}

server {
    listen 80;

    location / {
        proxy_pass http://my_backend;

        # 2. 💡 關鍵：強制將轉發協定改為 HTTP/1.1（1.0 不支援連線池保持）
        proxy_http_version 1.1;

        # 3. 💡 關鍵：清空 Connection 標頭，防止 Nginx 預設發送 "close"
        proxy_set_header Connection "";
    }
}
```

```text
upstream u_aaa {
    server slot-frontend-aaa-ci:80;
    keepalive 32;
    keepalive_requests 1000;
    keepalive_timeout 60s;
}

# 精準比對與強制補斜線，輸入 https://domain.com/aaa（結尾沒斜線）時，會精準命中這一條
# Nginx 回傳 308 Permanent Redirect，強迫瀏覽器重導向到帶有斜線的 https://domain.com/aaa/，並完整保留原本的 URL 參數
💡 為什麼用 308 而不用 301？ 308 可以確保瀏覽器在重導向時，不會把原本的 POST 請求偷偷變成 GET 請求，這在 API 路由中非常安全
location = /aaa {
    return 308 https://$host/aaa/$is_args$args;
}

location /aaa/ {
    # 處理 OPTIONS 預檢請求
    if ($request_method = OPTIONS) {
        add_header 'Access-Control-Max-Age' 1728000; # 快取 20 天
        add_header 'Content-Type' 'text/plain; charset=UTF-8';
        add_header 'Content-Length' 0;
        return 204;
    }

    # 網址路徑替換，使用者訪問：/aaa/index.html，實際轉發給後端：/lucky/index.html
    proxy_pass http://u_aaa/lucky/;
}
```
