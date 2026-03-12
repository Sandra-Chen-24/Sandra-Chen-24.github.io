+++
date = "2026-02-06T11:30:00+08:00"
draft = false
title = "Gemini Code Assist"
description = ""
tags = ["gemini"]
categories = ["ai"]
+++

## 使用

- 在 VScode 安專 plugin [Gemini Code Assist]，用聊天的方式下 prompt
- Custom Commands：常用 prompt 封裝成簡短的斜線指令 /unit-test
- 非 agent 模式: 問什麼答什麼(字典)，要自己複製貼上(出一張嘴)，只看當前檔案
- agent 模式：給它目標會自動執行修改程式，懂整個專案架構
  - Gemini CLI
    - Google 官方提供的 Google Cloud SDK (gcloud)
    - 社群開發的開源工具（gemini-cli）
  - GCA Agent Mode 打開 plugin 開關
- Gemini CLI Extensions 線上商店有很多插件可以安裝
- Conductor(上下文驅動開發)：停下來、想清楚、再開工，會先問使用者很多問題 [/conductor:setup]
- Spec Driven vs Vibe Coding
  - Spec Driven:Gemini CLI 寫完會自動幫你 git commit
  - Vibe Coding:關掉視窗就沒有紀錄
- Gemini CLI vs Antigravity
