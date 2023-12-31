+++
title = "How I Run openSUSE on Radxa ROCK 3A"
author = ["zzndb"]
description = "关于我是怎么在 rock3a 这个开发板上跑大蜥蜴"
date = 2023-12-31T23:50:00+08:00
lastmod = 2024-01-01T00:29:47+08:00
tags = ["packaging", "OBS", "rock3a", "openSUSE"]
categories = ["forfun"]
draft = false
+++

又是一年的最后一天，为了完成今年份博客更新任务，来写下应该是拖了一个月左右的这篇应该是折腾记录的东西。有生之年应该还有续集，因为目前整体还没达到预期的状态，比如还不能直接从固态启动系统……

<details>
<summary>一些无关紧要的前情提要，碎碎念</summary>
<div class="details">

大概是在去年七月份入手的 [Radxa ROCK 3A](https://wiki.radxa.com/Rock3/3a)，8G 内存版本。记得买之前正苦恼没有比较优雅的方法来挂之前整的一块 4T 移动硬盘，手里只有一个白嫖的树莓派 3B+，但碍于其 USB2.0 的速度，以及没有足够的电流来直接驱动，所以想要找一个至少得有 USB3.0 口子的板子来用，记得是在酷安看到有人分享类似需求来使用 rock3a 来折腾的经历，也没多想就在某宝入手了。到手之后才发现还是需要外接带供电的拓展坞才能稳定不掉盘。能选的系统不多，选了 Armbian 用着，顺便也开始想在这上面跑大蜥蜴，后来因为各种原因鸽了。

现在想来像在价格和生态方面都还挺坑的，当时我也没想到原来看似便宜的国产板子都差不多是这样，各玩儿各的，看似开源但不合到主线……
</div>
</details>


## TL;DR {#tl-dr}

了解这个板子所用 SOC 的[启动流程](https://opensource.rock-chips.com/wiki_Boot_option)，一开始准备构建镜像 by hand，但涉及太多并不懂的知识，转而借助大蜥蜴的基础设施（[openSUSE Build Service](https://build.opensuse.org/)），打包需要的前置软件包 [U-Boot](http://www.denx.de/wiki/U-Boot)，照着现有的 JeOS (Just Enough Operating System) [KIWI](https://osinside.github.io/kiwi/) 模板魔改。

{{< alert warning >}}
因为有太多没懂的细节，所以本文想来不会有啥技术含量，就是个流水帐。
{{< /alert >}}


## 打包 U-Boot {#打包-u-boot}

至少在重新捡起来折腾这个板子的 23 年 11 月，U-Boot 官方源码已经有了这个板子的构建配置 `rock-3a-rk3568_defconfig` ，一开始走了弯路去研究 Radax 提供的 [U-Boot 源码](http://www.denx.de/wiki/U-Boot)
确定需要的那什么 `.img .bin .itb` 文件怎么来的。后来才发现 U-Boot [文档](https://docs.u-boot.org/en/latest/board/rockchip/rockchip.html)中写得清楚又明白，连构建步骤都挨个写了，留下感动的泪水。

这个板子的 rk3568 在构建过程中需要使用到瑞芯微提供的实现私有的 binary 文件，于是仿照有开源实现的 [`arm-trusted-firmware-rk3399`](https://build.opensuse.org/package/show/devel:ARM:Factory:Contrib:Rockchip/arm-trusted-firmware) 使用 [rockchip-linux/rkbin](https://github.com/rockchip-linux/rkbin) 打包了一个 [`arm-private-firmware-rk3568`](https://build.opensuse.org/package/show/home:zzndb001:rk3568/arm-private-firmware-rk3568) 来提供构建过程中需要用到的 `bl31.elf` 。这里直接使用三方二进制打包决定了在有开源实现之前，我整的这些东西是只有在自己分支项目玩玩儿了。

参照其他瑞芯微板子修改 u-boot.spec 添加 `rock-3a-rk3568` 相关配置，为了后续使用 Btrfs 还修改了下上游 defconfig 加上默认 Btrfs 构建参数。

目前与大蜥蜴上游项目的差异[参见这里](https://build.opensuse.org/package/rdiff/home:zzndb001:rk3568/u-boot?opackage=u-boot&oproject=hardware%3Aboot&rev=37)。(还有一些为了实现直接固态启动的构建参数修改尝试，以及后续为了使用板子自带 PWM 风扇接口启用了对应的接口的修改，不过这些都是后话了)


## 打包 JeOS 镜像 {#打包-jeos-镜像}

同样是基于大蜥蜴[上游 JeOS 包](https://build.opensuse.org/package/show/openSUSE:Factory:ARM/JeOS)，参照已有的瑞芯微板子创建修改所需 KIWI 配置文件，[与大蜥蜴上游差异](https://build.opensuse.org/package/rdiff/home:zzndb001:rk3568/JeOS?opackage=JeOS&oproject=openSUSE%3AFactory%3AARM&rev=20)。

在配置文件中有两种启动方式

1.  配置 U-Boot 启动 GRUB2，再由 GRUB2 启动系统
2.  配置 U-Boot 直接加载，启动系统

两种方式区别是 U-Boot 在前面启动分区（[启动流程](https://opensource.rock-chips.com/wiki_Boot_option) boot.img 位置）读取的文件不同，U-Boot 会按照一定顺序去几个特定位置读取特定文件。这两种我试过都是可以的，目前仓库的可以通过两种方式启动，不过使用 boot.scr 的优先级高一些，会使用配置的这个启动脚本加载相关文件然后启动系统，当然也可以启动阶段任意键终止，在 U-Boot 终端使用 `bootefi` 启动 GRUB2

前面说到无法直接从固态启动的问题就是，我没找到配置能在使用自带 SPI flash 的时候默认启用板子的 PCI，然后就会识别不到 NVMe 设备然后报错，后面通过使用其他设备如 micro sdcard 上同样的 U-Boot 进入就能够启用并正常进入在 NVMe 上的系统。


## 刷入镜像 {#刷入镜像}

如果使用 micro sdcard 或者 emmc module 的 MMC 设备可以直接正常 dd 写入镜像然后使用，可参见[大蜥蜴任意 Arm 板子维基](https://en.opensuse.org/Category:ARM_devices)写入 JeOS 镜像部分，或者使用类似下面的命令，写入对应具体介质的 `/dev/mmcblk0` 设备

```bash
xzcat /path/to/image.raw.xz | sudo dd bs=4M of=/dev/mmcblk0 iflag=fullblock oflag=direct status=progress; sync
```

但是想要使用 NVMe 设备，需要额外的 micro sdcard 或者 emmc module，并在其中写入镜像并启动进入，在系统中向 NVMe 设备再次写入镜像，因为镜像的启动配置中 NVMe 设备优先级比 MMC 设备高（bootdevs="nvme mmc"），所以后续会直接使用 NVMe 设备中的系统。


## 一些问题 {#一些问题}

-   有线网卡无法直接使用，在[这里](https://lore.kernel.org/lkml/CANAwSgTLL3nJ5pUuaFpKe8tc6oVREo_WOJ+_Q3kO3OmgPTa0Bw@mail.gmail.com/#r)找到补丁，于是再次自己从大蜥蜴上游拉了 [kernel-source](https://build.opensuse.org/package/show/home:zzndb001:rk3568/kernel-source) 自己打了补丁，截止到写这篇文章还没合入主线

    <details>
    <summary>由于上面地址没直接给出补丁，这里给下补丁内容：</summary>
    <div class="details">

    ```patch
    diff --git a/arch/arm64/boot/dts/rockchip/rk3568-rock-3a.dts b/arch/arm64/boot/dts/rockchip/rk3568-rock-3a.dts
    index e05ab11..a872184 100644
    --- a/arch/arm64/boot/dts/rockchip/rk3568-rock-3a.dts
    +++ b/arch/arm64/boot/dts/rockchip/rk3568-rock-3a.dts
    @@ -583,7 +583,7 @@ &i2s2_2ch {

     &mdio1 {
        rgmii_phy1: ethernet-phy@0 {
    -		compatible = "ethernet-phy-ieee802.3-c22";
    +        compatible = "ethernet-phy-id001c.c916", "ethernet-phy-ieee802.3-c22";
            reg = <0x0>;
            pinctrl-names = "default";
            pinctrl-0 = <&eth_phy_rst>;
    ```
    </div>
    </details>


## 最后 {#最后}

虽然前面出现过，但项目在[这里](https://build.opensuse.org/project/show/home:zzndb001:rk3568)，如果有人有需要也可以直接用里面 JeOS-rock3a 构建出的镜像文件

不过入坑这板子，还用大蜥蜴的估计就我了. :)

等我折腾出来了直接从固态启动，应该会更新个非流水帐的续集。
