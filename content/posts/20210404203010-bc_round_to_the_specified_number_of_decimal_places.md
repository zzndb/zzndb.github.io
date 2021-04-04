+++
title = "bc round to the specified number of decimal places"
author = ["zzndb"]
description = "对 `bc` 的小数结果精度控制以及舍入的碎碎念"
date = 2021-04-04
publishDate = 2021-04-04
lastmod = 2021-04-04T22:37:56+08:00
tags = ["Shell Script"]
categories = ["code"]
draft = false
+++

`bc` 一个命令行计算器， `dc` 的继承者？

```bash
bc -l <<< "1/3"
```

```text
0.3333333333333333
```

提供了 **scale** 变量来控制结果小数位数

```bash
bc -l <<< "scale=3; 1/3"
```

```text
0.333
```

不过大概是出于精度考虑有时 **scale** 并不能得到指定结果精度

```bash
bc -l <<< "scale=3; a=0.333333; a+0"
```

```text
0.333333
```

可以通过对高精度小数进行除一操作得到指定结果精度（貌似有对其除就行）

```bash
bc -l <<< "scale=3; a=0.333333; a/1"
```

```text
0.333
```

对指定位数小数进行舍入

```bash
bc -l <<< "scale=3; a=0.333333; r=10^scale; ((a+a)*r+0.5)/r"
```

```text
0.667
```

BTW，直接用 `printf` 格式化也能进行舍入

```bash
printf "%.3f" $(bc -l <<< "scale=3; a=0.333333; a+a")
```

```text
0.667
```


## Reference {#reference}

-   `bc` manpages
-   <https://askubuntu.com/a/863756>
-   <https://askubuntu.com/a/179949>
