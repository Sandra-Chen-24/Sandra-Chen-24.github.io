+++
date = "2025-09-03T10:54:57+08:00"
draft = false
title = "Startup Go Test"
description = "開始撰寫測試案例"
tags = ["test"]
categories = ["golang"]
+++

## 前置作業

```text
# 安裝套件
$ go get github.com/stretchr/testify
$ go mod tidy

📌 檔案命名使用 func 名稱『大駝峰』改為『蛇型命名』(e.g. UpdateConfigmap -> update_configmap)
# Example
func (suite *ExampleTestSuite) SetupTest() {
    suite.VariableThatShouldStartAtFive = 5
}

// All methods that begin with "Test" are run as tests within a
// suite.
func (suite *ExampleTestSuite) TestExample() {
    assert.Equal(suite.T(), 5, suite.VariableThatShouldStartAtFive)
    suite.Equal(5, suite.VariableThatShouldStartAtFive)
}

// In order for 'go test' to run this suite, we need to create
// a normal test function and pass our suite to suite.Run
func TestExampleTestSuite(t *testing.T) {
    suite.Run(t, new(ExampleTestSuite))
}
```
