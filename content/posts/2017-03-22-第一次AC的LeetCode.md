---
title: 第一次AC的LeetCode
date: 2017-03-22T14:50:00+08:00
categories: Code
tags: [Leetcode]
description: 一道简单题，记的流水帐
---
是的，第一次
<!--more-->
当然前面也看过两道，貌似都是选的easy难度的。:joy:
当然听着室友淡定的谈着两百多道，一百多道，，，

那又怎样，还是蛮激动的:stuck_out_tongue:

当然其间犯了很多低级问题，以及情况考虑不完全等智商问题:confused:？看了看那个简单的 C 例子，我，，，,特地来记录一下:joy:

就是这个简单的数组题通过率也老高了的

***485. Max Consecutive Ones***

题目描述：*Given a binary array, find the maximum number of consecutive 1s in this array.*

举例：
    *Input: [1,1,0,1,1,1]
    Output: 3
    Explanation: The first two digits or the last three digits are consecutive 1s.
        The maximum number of consecutive 1s is 3.*

C例子代码如下
```c
int findMaxConsecutiveOnes(int* nums, int numsSize) {
 int max = 0;
 int sum = 0;
 for (int i=0; i<numsSize; i++)
 {
     sum = (sum+nums[i])*nums[i];
     if(max<sum){max=sum;}
 }
return max;
}
```
看看他的行数，我就不贴我的渣渣代码了，二十多行，也没有任何技巧？可言。
在我看来 `sum = (sum+nums[i])*nums[i];`为这例，我所不及的地方。
巧妙用了 1 与 0 在乘法运算中对结果带来的差异

以上，纪念第一次AC
