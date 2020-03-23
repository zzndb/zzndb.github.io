---
title: Shell Problems On LeetCode
date: 2020-03-02T16:28:00+08:00
categories: Code
tags: [Leetcode, "Shell Script"]
description: LeetCode 上的四道 Shell 题
---

目前只有四道（已经一年多过去了还是只有四道。。。

<!--more-->

# 192 Word Frequency

题目链接：<a target="_blank" href="https://leetcode.com/problems/word-frequency/">https://leetcode.com/problems/word-frequency/</a>
用人话说的题目描述：
给你一个文本 `words.txt` 里面包含若干行英文句子，统计每个单词的词频，以降序输出
例如输入：
```
the day is sunny the the
the sunny is is
```
正确输出：
```
the 4
is 3
sunny 2
day 1
```

## 一年前 AC 版本：
```
cat words.txt | sed -E "s/( )+/\n/g" | awk '{a[$0]++;} END {for (i in a) print i " " a[i];}' | sort -nrk 2 -t ' ' | awk '$2!="" {print $0}'
```
貌似我当年并不知道 `tr` ？竟然用 `sed` 进行空格替换处理，还贴心的为`sort`指定了分隔符，还二次使用了 `awk` 就为了去除可能在单词间多余的空格的情况。

也许是因为使用了不应该有的 `cat` 以及不知道 `tr` 使用了叫重的 `sed + awk` 完成本应该一个 `tr` 就能完成的工作，最后耗时 8ms ，现在来看打败了 8.85% 的 AC 提交者。

## 现在的 AC 版本：
```
tr -s " " "\n" < words.txt | awk 'BEING{}{key[$1]++}END{for (i in key) print i" "key[i]}' | sort -rnk 2
```
`tr`：预处理文本，格式化为每行一个单词，为后续处理做准备
 * `-s`：压缩重复匹配，这里处理单词间多于一个空格的情况
 * `" " "\n"`：替换前一个匹配空格到后面字符，这里替换为回车
 * `<`：直接重定向输入，避免使用无意义的 `cat` 程序
 * `words.txt`：目标文本
 
`awk`：完成主要的词频统计
`sort`：完成最后降序排序

 * `-r`：降序
 * `-n`：根据数字值排序
 * `-k`：指定排序关键字位置，这里为 2
 
最后耗时 0ms 打败 100% 的提交者？内存占用 3.3 MB 打败 86.21% 提交者。

# 193 Valid Phone Numbers

题目链接：<a target="_blank" href="https://leetcode.com/problems/valid-phone-numbers/">https://leetcode.com/problems/valid-phone-numbers/</a>
用人话说的题目描述：
给你一个文本文件`file.txt`每行包含一个电话号码，给你正确的格式要求`(xxx) xxx-xxxx or xxx-xxx-xxxx`打印出正确的电话号码

这个在一年前就试过了各种实现，都不太理想，让我现在想通过正则匹配实现，我也差不多只能想到`grep，awk，sed`来做，结果都不太好，最好还是 8ms 的运行时间，他们实现都大同小异，无非是用类似`^((\([0-9]{3}\)\ )|([0-9]{3}-))[0-9]{3}-[0-9]{4}*$`来匹配，当然实现中得注意命令行字符的意义，该转义转义（详见`regex` <a target="_blank" href=https://linux.die.net/man/7/regex>manpage</a>）。

## 一个 `grep` 版本：
```
grep "^\(\(([0-9]\{3\})\ \)\|\([0-9]\{3\}-\)\)[0-9]\{3\}-[0-9]\{4\}$" file.txt
```

# 194 Transpose File

题目链接：<a target="_blank" href="https://leetcode.com/problems/transpose-file/">https://leetcode.com/problems/transpose-file/</a>
用人话说的题目描述：
给你一个文本文件`file.txt`将内容进行转置。
输入例如：
```
ame age
alice 21
ryan 30
```
正确输出：
```
name alice ryan
age 21 30
```

因为之前太菜一直没做出来，就只有现在的版本了。

## 现在的 AC 版本：
```bash
awk -F' ' '
BEGIN {
    count=0;
}
# read all to a array
{
    for (j=1; j<=NF; j++){
        count++; 
        key[count]=$j;
    } 
    row=NR;
    col=NF;
}
END {
    for (i=1; i<=col; i++){
        tmp="";
        for (j=0; j<row; j++){
            if(tmp == "") {
                tmp=key[i+col*j];
            } 
            else {
                tmp=tmp" "key[i+col*j];
            }
        } 
    print tmp;
    }
}' file.txt
```

在 `awk` 的 `BEGIN` 部分初始化计数变量便于将所有字符串写入一个数组；在中间每一行都执行部分，通过内置变量 `NF` 得到列数，以将一行内容依次写入数组，顺便更新计数变量，得到行列数`row & col`；最后的 `END` 部分俩 `for` 循环打印转置后的每一行。

最关键的就是转置的算法，这里我通过观察找到的这个规律：
* 转置后有之前列数行，所以第一个 for 使用列数计数，从 1 开始是为了便于得到数组值（其实为 0 后面加 1 还更统一
* 转置后每一行有之前行数个元素，所以使用行数计数，从 0 开始是为了便于计算元素之前位置
* 通过具体例子分析不难得出后面元素值的计算公式
```
1  2  3  4
5  6  7  8
9  10 11 12
    ↓
1  5  9       #  1     1+col   1+col*(row-1)
2  6  10  =   #  2     2+col   3+col*(row-1)
3  7  11      #  *     *       *
4  8  12      #  col   col+col col+col*(row-1)
```
~~我上面这是什么玩意儿？？~~

最后耗时 4 ms 打败 98.17% 的提交者，内存占用 4.6 MB。

# 195 Tenth Line

题目链接：<a target="_blank" href="https://leetcode.com/problems/tenth-line/">https://leetcode.com/problems/tenth-line/</a>
用人话说的题目描述：
给你一个文本文件`file.txt`输出第十行。

一道真正的简单题，直接用 `awk` 或者 `sed` 指定行号就行

## `sed` 的 AC 版本
```
sed -n 10p file.txt
```
* `-n`：等效于 `--quiet or --silent`，抑制默认的匹配输出
* `10`：指定行号
* `p`：打印匹配
最后耗时 0 ms。

经试验用 `awk` 打印耗时 4 ms ，大概是 `awk` 依旧对每行都处理了，而 `sed` 直接输出对应行了。

---

以上。
