+++
date = "2026-06-15T14:30:00+08:00"
draft = false
title = "使用 partition"
description = ""
tags = ["partition"]
categories = ["DB"]
+++

## ❓ 完全複製一模一樣的整張大表（包含所有分區與資料）
👉 最快的方法是直接複製硬碟上的 .ibd 實體檔案 [還沒試過]

```text
## 在目的地建立一張結構相同的空表
CREATE TABLE aaa_clone LIKE aaa;

## 把新表的「衣服」脫掉（捨棄它的空檔案空間）
ALTER TABLE aaa_clone DISCARD TABLESPACE;

## 把舊表鎖定並刷入硬碟（提取實體檔案）
FLUSH TABLES aaa FOR EXPORT;

## 作業系統底層（OS）複製檔案
去 MySQL 的 data 目錄下，把 aaa#p#*.ibd（所有分區的實體檔案）直接 cp (複製) 一份，並改名為 aaa_clone#p#*.ibd

## 解除舊表鎖定
UNLOCK TABLES;

## 讓新表「穿上衣服」（載入剛剛複製過來的檔案）
ALTER TABLE aaa_clone IMPORT TABLESPACE;
```

👉 LOAD DATA LOCAL INFILE (檔案在工程師的本機)

```text
## 調整 TablePlus 連線設定
選擇 「Edit...」 (編輯連線) -> 「Other options」-> ENABLE LOAD DATA LOCAL INFILE

## 用 UI Import
⚠️ 超級慢

## 先把資料 Export 出來
### 切割成小檔案
```text
tail -n +2 slotWagers-0531.csv | split -l 300000 - "split_temp_" && for f in split_temp_*; do head -n 1 slotWagers-0531.csv | cat - "$f" > "slotWagers-0531-${f#split_temp_}.csv" && rm "$f"; done
```text

### 批量倒入資料表 [300000筆大概兩分鐘]
```text
LOAD DATA LOCAL INFILE '/path/to/your/file.csv'
INTO TABLE your_table_name
CHARACTER SET utf8mb4           -- 🎯 指定檔案編碼（防止中文亂碼）
FIELDS TERMINATED BY ','        -- 🎯 欄位與欄位之間的分隔符號（CSV 通常是逗號）
ENCLOSED BY '"'                 -- 🎯 欄位是否用雙引號包起來（選填）
LINES TERMINATED BY '\n'        -- 🎯 換行符號（Windows 常用 \r\n，Linux 常用 \n）
IGNORE 1 LINES                  -- 🎯 跳過第一行（通常第一行是標題欄位名）
(col1, col2, col3);             -- 🎯 對應資料表的實體欄位順序（選填）
```

## 用指令
INSERT INTO ${table_name}_TestPartitions SELECT * FROM ${table_name} WHERE DATE(created_at) = "2026-03-26";
```

## Partition
❓切完可以還原嗎
👉 可以，而且完全不會掉資料，但需要時間與硬碟空間，因為這涉及實體檔案的合併與重寫。如果表資料量極大（例如幾百 GB），這個指令會跑非常久，且在跑的期間會鎖表（Lock Table），並吃掉雙倍的硬碟空間。強烈建議在離峰時間（例如凌晨）執行

```text
ALTER TABLE aaa REMOVE PARTITIONING;
```

```text
## 檢查 partition 清單
SELECT
    PARTITION_NAME,
    PARTITION_DESCRIPTION,
    TABLE_ROWS
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = '${table_name}'
ORDER BY PARTITION_ORDINAL_POSITION;
⚠️ TABLE_ROWS 數量很不準確

✨✨✨ ## 檢查各 PARTITION 資料數量
SELECT COUNT(*) AS pmax_rows
FROM ${table_name} PARTITION (pmax);
👉 如果 pmax_rows > 0，先補缺少的 partition，再確認資料已移出 pmax

## 初始 partition
✨✨✨ 分區表在建立時，必須將分區欄位（通常是時間欄位）納入 PRIMARY KEY 之中
CREATE TABLE IF NOT EXISTS `${table_name}` (
    `wager_id` varchar (40) NOT NULL DEFAULT '0' COMMENT '唯一, 單向遞增, 由外部產生',
    `player_id` varchar(25) NOT NULL DEFAULT '0' COMMENT '用戶編號',
    `game_id` int(11) NOT NULL DEFAULT '0' COMMENT '遊戲ID',
    `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`wager_id`,`created_at`),
    KEY `PlayerID` (`player_id`),
    KEY `IX_AddDate` (`created_at`),
    KEY `IX_WagerIDGameIDPlayerID` (`wager_id`,`game_id`,`player_id`),
    KEY `IX_GameIDPlayerID` (`game_id`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='遊戲主單'
PARTITION BY RANGE COLUMNS (`created_at`) (
    PARTITION p202605a VALUES LESS THAN ('2026-05-16 00:00:00'),
    PARTITION p202605b VALUES LESS THAN ('2026-06-01 00:00:00'),
    PARTITION p202606a VALUES LESS THAN ('2026-06-16 00:00:00'),
    PARTITION p202606b VALUES LESS THAN ('2026-07-01 00:00:00'),
    PARTITION p202607a VALUES LESS THAN ('2026-07-16 00:00:00'),
    PARTITION p202607b VALUES LESS THAN ('2026-08-01 00:00:00'),
    PARTITION p202608a VALUES LESS THAN ('2026-08-16 00:00:00'),
    PARTITION p202608b VALUES LESS THAN ('2026-09-01 00:00:00'),
    PARTITION pmax VALUES LESS THAN (MAXVALUE)
);

## 現存表新增 partition
⚠️ 這會重建表，正式環境要安排維護時段
ALTER TABLE ${table_name}
PARTITION BY RANGE COLUMNS (`created_at`) (
    PARTITION p202605a VALUES LESS THAN ('2026-05-16 00:00:00'),
    PARTITION p202605b VALUES LESS THAN ('2026-06-01 00:00:00'),
    PARTITION p202606a VALUES LESS THAN ('2026-06-16 00:00:00'),
    PARTITION p202606b VALUES LESS THAN ('2026-07-01 00:00:00'),
    PARTITION p202607a VALUES LESS THAN ('2026-07-16 00:00:00'),
    PARTITION p202607b VALUES LESS THAN ('2026-08-01 00:00:00'),
    PARTITION p202608a VALUES LESS THAN ('2026-08-16 00:00:00'),
    PARTITION p202608b VALUES LESS THAN ('2026-09-01 00:00:00'),
    PARTITION pmax VALUES LESS THAN (MAXVALUE)
);

## 從 pmax 拆出下一段半月 partition e.g. 新增 2026 年 9 月上半月
ALTER TABLE ${table_name}
REORGANIZE PARTITION pmax INTO (
    PARTITION p202609b VALUES LESS THAN ('2026-09-16 00:00:00'),
    PARTITION pmax VALUES LESS THAN (MAXVALUE)
);

❗ p202607a 放錯區，應該要放到 p202606b
ALTER TABLE ${table_name}
REORGANIZE PARTITION p202607a INTO (
    PARTITION p202606b VALUES LESS THAN ('2026-07-01 00:00:00'),
    PARTITION p202607a VALUES LESS THAN ('2026-07-16 00:00:00')
);

❗ p202607a 放錯區，應該要放到 p202606b
ALTER TABLE ${table_name}
REORGANIZE PARTITION p202603b, p202604a, p202604b, p202605a INTO (
    -- 🎯 將這四個舊分區打包成一個大分區，名字沿用 p202605a
    -- ⚠️ 邊界時間必須設定為原本 p202605a 的時間點（例如 2026-05-16）
    PARTITION p202605a VALUES LESS THAN ('2026-05-16 00:00:00')
);

## 刪除過期 partition
ALTER TABLE ${table_name} DROP PARTITION p202605a;
⚠️ DROP PARTITION 會刪除該 partition 內所有資料
```

## ⚠️ 玩 Partition 絕對不能踩的「三大血淚大坑」

```text
## 分區欄位一定要加入所有唯一索引（Unique / Primary Key）
e.g. UNIQUE KEY (user_id) -> UNIQUE KEY (user_id, created_at)，否則建表會直接被拒絕

## 查詢（SELECT）語法一定要帶上時間條件（Partition Pruning）
👉 否則 MySQL 找不到時間線索，會強行把 30 個 Partition 檔案全部打開掃描一遍（Partition Scan），反而比沒切之前還要慢

## 注意 MAXVALUE 的卡死風險
👉 Event 因為伺服器重啟或卡住沒執行，新資料會全部塞進 p_max 這個分區裡。久而久之 p_max 就會變成一個巨大的髒分區，未來你要再切分（Reorganize）會引發長時間的鎖表
✨✨✨ 黃金維運守則：自動化腳本最好提早建好未來的分區，保留容錯 buffer，並設定監控告警
```

## 自動化：利用 MySQL 內建的 EVENT 搭配 STORED PROCEDURE

```text
## 確保 MySQL 的 Event 功能有啟動
SHOW VARIABLES LIKE 'event_scheduler';

## 撰寫自動建立與刪除的 Stored Procedure
DELIMITER $$

CREATE PROCEDURE sp_rolling_check_half_month_partitions()
BEGIN
    DECLARE v_months_ahead INT DEFAULT 0;
    DECLARE v_check_date DATE;
    DECLARE v_year_month VARCHAR(6);
    
    DECLARE v_p_name_a VARCHAR(20);
    DECLARE v_p_name_b VARCHAR(20);
    DECLARE v_border_a VARCHAR(30);
    DECLARE v_border_b VARCHAR(30);
    DECLARE v_sql VARCHAR(1000);

    -- 迴圈檢查：從當月(0)開始，一路檢查到未來第 3 個月(3)，總共掃描 4 個年份月份
    WHILE v_months_ahead <= 3 DO
        -- 1. 計算目標月份的基準日期
        SET v_check_date = DATE_ADD(CURDATE(), INTERVAL v_months_ahead MONTH);
        SET v_year_month = DATE_FORMAT(v_check_date, '%Y%m');
        
        -- 2. 定義該月份 a 和 b 的分區名稱
        SET v_p_name_a = CONCAT('p', v_year_month, 'a');
        SET v_p_name_b = CONCAT('p', v_year_month, 'b');
        
        -- 3. 定義該月份 a 和 b 的 VALUES LESS THAN 邊界時間
        SET v_border_a = DATE_FORMAT(CONCAT(DATE_FORMAT(v_check_date, '%Y-%m-'), '16 00:00:00'), '%Y-%m-%d %H:%i:%s');
        SET v_border_b = DATE_FORMAT(DATE_ADD(LAST_DAY(v_check_date), INTERVAL 1 DAY), '%Y-%m-%d 00:00:00');

        -- 【檢查 A 分區】：例如 p202604a
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.partitions 
            WHERE table_name = 'MainWagers_TestPartitions' -- 請替換成你的實體資料表名稱
              AND partition_name = v_p_name_a
        ) THEN
            -- 發現破洞，立刻從 pmax 重新切分出來
            SET v_sql = CONCAT(
                'ALTER TABLE MainWagers_TestPartitions REORGANIZE PARTITION pmax INTO (',
                'PARTITION ', v_p_name_a, ' VALUES LESS THAN (\'', v_border_a, '\'), ',
                'PARTITION pmax VALUES LESS THAN (MAXVALUE))'
            );
            -- 標準換行執行，防範語法解析錯誤
            SET @v_execute_sql = v_sql; 
            PREPARE stmt FROM @v_execute_sql; 
            EXECUTE stmt; 
            DEALLOCATE PREPARE stmt;
        END IF;

        -- 【檢查 B 分區】：例如 p202604b
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.partitions 
            WHERE table_name = 'MainWagers_TestPartitions' -- 請替換成你的實體資料表名稱
              AND partition_name = v_p_name_b
        ) THEN
            -- 發現破洞，立刻從 pmax 重新切分出來
            SET v_sql = CONCAT(
                'ALTER TABLE MainWagers_TestPartitions REORGANIZE PARTITION pmax INTO (',
                'PARTITION ', v_p_name_b, ' VALUES LESS THAN (\'', v_border_b, '\'), ',
                'PARTITION pmax VALUES LESS THAN (MAXVALUE))'
            );
            -- 標準換行執行，防範語法解析錯誤
            SET @v_execute_sql = v_sql; 
            PREPARE stmt FROM @v_execute_sql;
            EXECUTE stmt; 
            DEALLOCATE PREPARE stmt;
        END IF;

        -- 進入下一個月份的檢查
        SET v_months_ahead = v_months_ahead + 1;
    END WHILE;
    
END$$

DELIMITER ;
---
DELIMITER $$

CREATE EVENT ev_half_month_rolling_inspector
ON SCHEDULE EVERY 1 DAY
STARTS DATE_FORMAT(NOW(), '%Y-%m-%d 04:00:00') -- 每天凌晨 04:00 [因為 DB 時間要 -8 小時，所以會在中午執行]
DO
BEGIN
    -- 當 1 號 或 16 號時，才呼叫 Procedure
    IF DAY(CURDATE()) = 1 OR DAY(CURDATE()) = 16 THEN
        CALL sp_rolling_check_half_month_partitions();
    END IF;
END$$

DELIMITER ;
---

## 列出所有 SP 跟 EVENT
SHOW PROCEDURE STATUS WHERE Db = DATABASE();

SHOW EVENTS;
SELECT 
    EVENT_NAME AS '事件名稱',
    STATUS AS '目前狀態', -- ENABLED 代表有在跑，DISABLED 代表停用
    INTERVAL_VALUE AS '執行間隔',
    INTERVAL_FIELD AS '單位',
    LAST_EXECUTED AS '上一次執行時間'
FROM information_schema.EVENTS 
WHERE EVENT_SCHEMA = DATABASE();

DROP EVENT IF EXISTS event_name;