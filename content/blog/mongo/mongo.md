+++
date = "2026-07-08T10:00:00+08:00"
draft = false
title = "mongodb 基礎使用"
description = ""
tags = ["mongodb"]
categories = ["DB"]
+++


## 連線

```text
mongosh -u root -p $PWD --authenticationDatabase admin admin
✨✨✨✨✨✨✨✨✨✨
rs0 [direct: primary] admin> show dbs
admin   140.00 KiB
config  300.00 KiB
local   444.00 KiB
wagers   40.00 KiB
✨✨✨✨✨✨✨✨✨✨
⚠️ mongosh -u root -p $PWD --authenticationDatabase wagers wagers 會 MongoServerError: Authentication failed.
✨✨✨✨✨✨✨✨✨✨
rs0 [direct: primary] admin> use wagers
switched to db wagers
rs0 [direct: primary] wagers>

// 寫入一筆測試資料到 test_collection 資料表
db.test_collection.insertOne({ name: "gemini", status: "ok", date: new Date() })
// 查詢寫入的資料
db.test_collection.find()

rs0 [direct: primary] wagers> show tables
test_collection
✨✨✨✨✨✨✨✨✨✨
```

```text
mongosh -u app-user -p $PWD --authenticationDatabase wagers wagers
## go 程式連線設定
mongodb://app-user:$PWD@mongodb-headless.default.svc.cluster.local:27017/wagers?authSource=wagers&replicaSet=mongodb
⚠️ &directConnection=true [用 MongoDB Compass 要加]
```

## 指令

```text
## 刪除表
db.test_collection.drop();

## 建立有 index 的表
db.test_collection.createIndex(
  { "createdAt": 1 }, 
  { expireAfterSeconds: 30 }
);

✨ db.test_collection.insertOne({
  "createdAt": new Date()
});
⚠️ 負責刪除過期資料的背景執行緒每 60 秒才開機運作一次，所以當你的資料時間到了，它可能還會多存活個幾秒到一分鐘，這是正常的

✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨
🔄 進階讓「每一筆資料」的過期時間不一樣
✨ 將 expireAfterSeconds 設為 0
db.test_collection.createIndex(
  { "expireAt": 1 }, 
  { expireAfterSeconds: 0 } // 設為 0 代表「只要到了欄位裡寫的時間，就立刻刪除」
)

⚠️ 7 分鐘，應該是 7 * 60 * 1000 [8 * 60 * 60 * 1000 👉 +8 hr]
// 普通會員：1天後過期
db.test_collection.insertOne({
  "username": "normal_user",
  "expireAt": new Date(Date.now() + 24 * 60 * 60 * 1000) 
})

// VIP 會員：7天後過期
db.test_collection.insertOne({
  "username": "vip_user",
  "expireAt": new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) 
})

db.test_collection.insertOne({
  "username": "normal_user_2",
  "expireAt": new Date(Date.now() + 2 * 60 * 1000) 
})
✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨

## 建立唯一鍵
db.test_collection.createIndex({ email: 1 }, { unique: true });
db.test_collection.createIndex({ user_id: 1, round_id: 1 }, { unique: true });

## 查看 Index
db.test_collection.getIndexes();

## 刪除某個 Index
db.test_collection.dropIndex({ age: 1 })
⚠️ 1：升序索引；-1：降序索引
```

