---
layout: post
title: A note for myself
date: 2021-09-27 09:00:00 +03000
tags: golang
---

When you need to do something with strings length, consider using `unicode/utf8` package. len() function doesn't work good for special character containing strings. For example les accents in French or modified letters in Turkish alphabet.

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println(len("Sadıç")) // will print 7
	fmt.Println(len("Adélaïde")) // will print 10
}
```

You should use `unicode/utf8` package to measure length of unicode strings.

```go
package main

import (
	"fmt"
	"unicode/utf8"
)

func main() {
	fmt.Println(utf8.RuneCountInString("Sadıç")) // 5
	fmt.Println(utf8.RuneCountInString("Adélaïde")) // 8

}
```
