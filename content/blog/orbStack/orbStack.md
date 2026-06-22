+++
date = "2026-03-05T14:30:00+08:00"
draft = false
title = "使用 OrbStack"
description = ""
tags = ["orbStack"]
categories = ["docker"]
+++

## 使用 OrbStack

```text
# 安裝 OrbStack
brew install orbstack

# Switch to OrbStack
docker context use orbstack

# 設定 OrbStack 可以使用的硬體資源
點擊「Settings…」打開設定面板 -> 切到 System 的 tab，就可以設定資源的使用量 [預設是記憶體 8 G]

# 查看目前所有機器狀態
orb list

# 拉 image
docker pull

# 查看建置歷史
docker history <IMAGE_ID_或_名稱>

# 查看完整中繼資料
docker inspect <IMAGE_ID_或_名稱>
```

## 整理 kubectx 可選擇叢集

```text
# 設定資料在 ~/.kube/config
⭐ 標準指令刪除 (最安全)
# 1. 先列出所有 context，確認哪些是棄用的
kubectx

# 2. 刪除對應的 cluster 與 user (選配，乾淨度+100)
# 因為 context 只是連接 cluster 和 user 的橋樑，刪除 context 後，背後的 cluster 設定通常還在
kubectl config delete-cluster <CLUSTER_名稱>
kubectl config delete-user <USER_名稱>

⭐ 使用 kubecm (最強大的工具)
brew install kubecm
kubecm delete：會跳出一個像 kubectx 一樣的選單，你可以按空白鍵多選，一次把所有棄用的 context 全部勾掉

💡 檢查「殘留物」：刪除 Context 後，最煩的是 clusters 和 users 區塊還留著一堆沒用的資料
# 找出所有 cluster 名稱
kubectl config view -o jsonpath='{.clusters[*].name}'
```
