+++
date = "2025-12-15T11:30:00+08:00"
draft = false
title = "deployment"
description = ""
tags = ["deployment"]
categories = ["k8s"]
+++

Deployment's label selector is immutable after it gets created.

## 查看 NS 還有什麼資源殘留
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n ${NS}

