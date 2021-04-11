+++
title = "bc round to the specified number of decimal places"
author = ["zzndb"]
description = "对 `bc` 的小数结果精度控制以及舍入的碎碎念"
date = 2021-04-04
publishDate = 2021-04-04
lastmod = 2021-04-11T20:45:30+08:00
tags = ["Shell Script"]
categories = ["code"]
draft = false
+++

`bc` ，一个命令行计算器， ~~`dc` 的继承者？~~ 也许是继承者，不过更是 POSIX 标准的一部分

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

需要注意的是，在舍入前有进行会影响精度的操作（如做除法）会按指定位数丢失后面精度，让后面的一通舍入操作失败

```bash
bc -l <<< "scale=3; a=0.333333; r=10^scale; ((a+a)/1*r+0.5)/r"
```

```text
0.666
```

不过，这对这个看起来只是个计算器，而实则是个任意精度计算语言（An arbitrary precision calculator language）的 `bc` 来说不算啥问题，你可以先算好，再限制精度来计算舍入。

```bash
bc -l <<< "a=0.333333; ra=(a+a)/1; scale=3; r=10^scale; (ra*r+0.5)/r"
```

```text
0.667
```

<details>
<summary>
既然是个语言，你还能在里面编程……
</summary>
<p class="details">

来自其 manpage 中一个计算自然常数 e 的 1-10 次幂估算值的例子：

```bash
bc -l <<< \
"
         scale = 20
         define e(x){
             auto a, b, c, i, s
             a = 1
             b = 1
             s = 1
             for (i = 1; 1 == 1; i++){
                 a = a*x
                 b = b*i
                 c = a/b
                 if (c == 0) {
                      return(s)
                 }
                 s = s+c
             }
         }
         for (i = 1; i <= 10; ++i) {
             e(i)
         }
"
```

| 2.718281828459045  |
|--------------------|
| 7.38905609893065   |
| 20.085536923187668 |
| 54.598150033144236 |
| 148.4131591025766  |
| 403.4287934927351  |
| 1096.6331584284585 |
| 2980.9579870417283 |
| 8103.083927575384  |
| 22026.465794806718 |

不过 POSIX 标准里的 `bc` 并没有位运算…… sigh
</p>
</details>

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
