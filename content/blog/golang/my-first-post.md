+++
date = "2025-08-27T11:37:57+08:00"
draft = false
title = "My First Post"
description = "測試使用 Hugo Theme Stack"
tags = ["example", "hugo"]
categories = ["demo"]
+++

這是我的第一篇 Hugo 文章！

## 小節
- 支援 Markdown 語法
- 可以用 shortcode 插入圖片或程式碼


err = os.MkdirAll(dirPath, os.ModePerm)
os.ModePerm -> 0777 代表 所有人都可讀寫執行，這對安全性風險很大
0750：Owner 可讀寫執行，Group 可讀執行，其他人無法存取（符合 gosec 要求）。
如果完全不需要 Group 存取，可以用 0700（Owner 全權，其他人完全禁止)

[Go 指南](https://tour.go-zh.org/welcome/1)
## [入門教材](https://tour.go-zh.org/welcome/1)

```text
# fmt.Printf("現在你有了 %g 個問題。\n", math.Sqrt(7))
🔢 整數類
  %b：二進位表示法
  %c：Unicode 字元（對應整數的 Unicode code point）
  %d：十進位整數
  %o：八進位整數
  %q：單引號括起來的字元常數，必要時會做跳脫
  %x：十六進位（小寫 a-f）
  %X：十六進位（大寫 A-F）
  %U：Unicode 格式 U+1234
🔤 字串與切片
  %s：字串本身
  %q：雙引號括起來的字串，必要時會做跳脫
  %x：字串或 []byte 轉十六進位（小寫）
  %X：字串或 []byte 轉十六進位（大寫，字母 A-F）
🔬 浮點數與複數
  %b：科學記號，以二進位表示浮點數（指數部分是二的冪）
  %e：科學記號（小寫 e，如 -1.234000e+06）
  %E：科學記號（大寫 E，如 -1.234000E+06）
  %f：小數點表示法（不含指數，如 123.456000）
  %F：等同於 %f
  %g：自動選擇 %e 或 %f（保證最簡潔的輸出）
  %G：自動選擇 %E 或 %F
📦 通用類
  %v：值的預設格式
  %+v：值的預設格式，並輸出 struct 的欄位名
  %#v：Go 語法表示法（能直接貼回程式）
  %T：值的型別
  %%：字面上的百分號

## 範例
type User struct {
    Name string
    Age  int
}
u := User{"Alice", 30}

fmt.Printf("%v\n", u)   // {Alice 30}
fmt.Printf("%+v\n", u)  // {Name:Alice Age:30}
fmt.Printf("%#v\n", u)  // main.User{Name:"Alice", Age:30}
fmt.Printf("%T\n", u)   // main.User
```

```go
/**
短变量声明
在函数中，短赋值语句 := 可在隐式确定类型的 var 声明中使用。
函数外的每个语句都 必须 以关键字开始（var、func 等），因此 := 结构不能在函数外使用。
**/

package main

import "fmt"
var i, j int = 1, 2
func main() {
	k := 3
	c, python, java := true, false, "no!"

	fmt.Println(i, j, k, c, python, java)
}

```

## switch

```go
// 由上而下判斷，有符合條件則退出
// 無條件的 switch 跟 switch true 一樣
```

## defer

```go
// 後進先出
```

## pointer

```go
// Go 沒有指針運算
// 指針保存內存地址 [*T 是指向 T 類型的指針]
func main() {
	i, j := 42, 2701
  fmt.Println(&i) // [0xc0000a0040]
  fmt.Println(&j) // [0xc000010078]
	p := &i         // 指向 i
  fmt.Println(p)  // [0xc0000a0040]
  fmt.Println(&p) // [0xc0000a2040]
	fmt.Println(*p) // 通过指针读取 i 的值 [42]
	*p = 21         // 通过指针设置 i 的值
	fmt.Println(i)  // 查看 i 的值 [21]

	p = &j         // 指向 j
  fmt.Println(p) // [0xc000010078]
	*p = *p / 37   // 通过指针对 j 进行除法运算
	fmt.Println(j) // 查看 j 的值 [73]
}

// 結構體指針
type Vertex struct {
	X int
	Y int
}

func main() {
	v := Vertex{1, 2}
	p := &v
	(*p).X = 1e9 // 等同於 p.X
	fmt.Println(v) // [1000000000,2]
}
```

## slice

```go
func main() {
	primes := [6]int{2, 3, 5, 7, 11, 13}

	var s []int = primes[1:4] // [3, 5, 7]
	fmt.Println(s)
}

// slice 不儲存數據，只描述數組中的一段
func main() {
	names := [4]string{
		"John",
		"Paul",
		"George",
		"Ringo",
	}
	fmt.Println(names) // [John Paul George Ringo]

	a := names[0:2]
	b := names[1:3]
	fmt.Println(a, b) // [John Paul] [Paul George]

	b[0] = "XXX"
	fmt.Println(a, b) // John XXX] [XXX George]
	fmt.Println(names) // [John XXX George Ringo]
}

// len 與 cap [長度與容量]
func main() {
	s := []int{2, 3, 5, 7, 11, 13}
	printSlice(s) // len=6 cap=6 [2 3 5 7 11 13]

	// 截取切片使其长度为 0
	s = s[:0]
	printSlice(s) // len=0 cap=6 []

	// 扩展其长度
	s = s[:4]
	printSlice(s) // len=4 cap=6 [2 3 5 7]

	// 舍弃前两个值
	s = s[2:]
	printSlice(s) // len=2 cap=4 [5 7]
}

func printSlice(s []int) {
	fmt.Printf("len=%d cap=%d %v\n", len(s), cap(s), s)
}

// 切片的零值是 nil
func main() {
	var s []int
	fmt.Println(s, len(s), cap(s)) // [] 0 0
	if s == nil {
		fmt.Println("nil!")
	}
}

// 用 make 建立 slice
func main() {
	a := make([]int, 5)
	printSlice("a", a) // a len=5 cap=5 [0 0 0 0 0]

	b := make([]int, 0, 5) // 第三個参數可以指定容量
	printSlice("b", b) // b len=0 cap=5 []

	c := b[:2]
	printSlice("c", c) // c len=2 cap=5 [0 0]

	d := c[2:5]
	printSlice("d", d) // d len=3 cap=3 [0 0 0]
}

func printSlice(s string, x []int) {
	fmt.Printf("%s len=%d cap=%d %v\n",
		s, len(x), cap(x), x)
}
```

## 函數

```go
// 函數閉包
func adder() func(int) int {
	sum := 0
	return func(x int) int {
		sum += x
		return sum
	}
}

func main() {
	pos, neg := adder(), adder()
	for i := 0; i < 10; i++ {
		fmt.Println(
			pos(i),
			neg(-2*i),
		)
	}
}

// fibonacci 函数
// fibonacci 是返回一个「返回一个 int 的函数」的函数
func fibonacci() func() int {
}

func main() {
	f := fibonacci()
	for i := 0; i < 10; i++ {
		fmt.Println(f())
	}
}
```

## 方法

```go
// 帶特殊接收者參數的函數

type Vertex struct {
	X, Y float64
}

func (v Vertex) Abs() float64 {
	return math.Sqrt(v.X*v.X + v.Y*v.Y)
}

func (v *Vertex) Scale(f float64) {
	v.X = v.X * f
	v.Y = v.Y * f
}

func main() {
	v := Vertex{3, 4}
	v.Scale(10)
	fmt.Println(v.Abs()) // 50
}

// 使用 v *Vertex
{30 40}
50
// 使用 v Vertex
{3 4}
5
```

## 泛型

```go
// comparable 為由所有可比較類型（布爾，數字，字符串，指針，通道，可比較類型的數組，其字段都是可比較類型的結構）實現的接口
// Index 返回 x 在 s 中的下标，未找到则返回 -1。
// Ｔ可以改成任意名稱
func Index[T comparable](s []T, x T) int {
	for i, v := range s {
		// v 和 x 的类型为 T，它拥有 comparable 可比较的约束，
		// 因此我们可以使用 ==。
		if v == x {
			return i
		}
	}
	return -1
}

func main() {
	// Index 可以在整数切片上使用
	si := []int{10, 20, 15, -10}
	fmt.Println(Index(si, 15))

	// Index 也可以在字符串切片上使用
	ss := []string{"foo", "bar", "baz"}
	fmt.Println(Index(ss, "hello"))
}

// any
// List 表示一个可以保存任何类型的值的单链表。
type List[T any] struct {
	next *List[T]
	val  T
}

func (l *List[T]) Append(v T) {
	curr := l
	for curr.next != nil {
		curr = curr.next
	}
	curr.next = &List[T]{val: v}
}

func (l *List[T]) Print() {
	curr := l.next // 跳過頭節點 (dummy head)
	for curr != nil {
		fmt.Printf("%v -> ", curr.val)
		curr = curr.next
	}
	fmt.Println("nil")
}

func main() {
	// 建立一個 int 的鏈表
	intList := &List[int]{}
	intList.Append(10)
	intList.Append(20)
	intList.Append(30)
	fmt.Print("intList: ")
	intList.Print()

	// 建立一個 string 的鏈表
	strList := &List[string]{}
	strList.Append("Go")
	strList.Append("is")
	strList.Append("fun")
	fmt.Print("strList: ")
	strList.Print()
}
```
