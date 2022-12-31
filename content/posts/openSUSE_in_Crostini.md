+++
title = "Run openSUSE in your Chrombook Crostini"
author = ["zzndb"]
description = "Chromebook Crostini 上跑 openSUSE 作为默认 Linux 环境的踩坑指北。"
date = 2022-12-31T21:42:00+08:00
lastmod = 2022-12-31T22:21:44+08:00
tags = ["packaging", "OBS", "Crostini", "openSUSE"]
categories = ["forfun"]
draft = false
+++

又一次手抖在进入了开发者模式的 Chromebook 开机确认关闭完整性校验时按了 Enter，去年某鱼入手的星星星的 Chromebook Pro 重置了……

好在之前有在吃灰前备份大部分数据到外置 SD 卡上，趁这次机会重新配置一遍随便完成这篇早该完成（大概是打的所需配置包基本稳定的去年十月份）的踩坑记录，随便完成今年的第一篇也是最后一篇博客更新。内容基于当前 ChromeOS 版本 108 的配置记录以及去年的笔记备份。


## TL;DR {#tl-dr}

总所周知目前 ChromeOS 的 Linux 环境是跑在一个虚拟机中的 LXD 容器，所以基本上分两步：

1.  新建和默认 Debian 额外设备配置相同的 openSUSE 容器，并在其中配置所需的一揽子配置来完成和外部 ChromeOS 交互集成。
2.  替换在 Crostini 中默认运行的 Debian 容器为 openSUSE 容器。


## 配置容器 {#配置容器}

在操作之前需要已启用 Linux 环境，也就是有了一个叫 `termina` 的虚拟机跑着默认叫 `penguin` 的 Debian 容器

-   **ctrl+alt+t** 快捷键呼出 **crosh** 窗口，键入 `vms list` 确认虚拟机 `termina` 存在
-   `vsh termina` 进入虚拟机，键入 `lxc list` 确认容器 `penguin` 存在
-   接着正常使用 lxc 创建一个 openSUSE 容器
    ```bash
    # 参考流程
    lxc remote add tuna-images https://mirrors.tuna.tsinghua.edu.cn/lxc-images/ --protocol=simplestreams
    lxc launch tuna-images:opensuse/15.4 oS
    lxc stop oS
    ```
-   按照原有 `penguin` 配置我们新的容器

    建议自行对照 `lxc config show penguin` 进行配置
    ```bash
    # 参考流程
    lxc config device add oS ssh_host_key disk source=/run/sshd/penguin/ssh_host_key path=/dev/.ssh/ssh_host_key
    lxc config device add oS ssh_authorized_keys disk source=/run/sshd/penguin/ssh_host_key path=/dev/.ssh/ssh_authorized_keys
    lxc config device add oS container_token disk source=/run/tokens/penguin_token path=/dev/.container_token
    # 之前好像没有这个设备，还是照着配了
    lxc config device add oS /dev/snd/pcmC0D0c unix-char path=/dev/snd/pcmC0D0c mode=0666 minor=24 major=116
    ```

-   进入新的容器进行必要配置
    ```bash
    # 参考流程
    lxc start oS
    lxc exec oS -- bash

    # 修改root密码，后续会用到
    passwd
    # 后续配置包中配置了 wheel 所在组免密操作
    groupadd wheel
    # 新建用户，建议还是和启用 Linux 环境时取的用户名一致，以下以 name_here 指代
    useradd -m -u 1000 -g users -G wheel name_here
    usermod -aG audio zdb # pluseaudio
    passwd name_here

    zypper in --no-recommends vim dracut
    # 建议修改如下配置，默认不安装推荐
    vim /etc/zypp/zypper.conf
    # installRecommends = no

    zypper ar obs://home:zzndb001 zzndb001
    sed -i 's|/openSUSE_Leap_|/|' /etc/zypp/repos.d/zzndb001.repo
    zypper in cros-container-guest-tools

    exit
    ```
    接下来使用普通用户完成剩下配置
    ```bash
    lxc stop penguin
    lxc console oS
    # 使用上面创建用户登录

    # 启用集成相关服务
    systemctl --user enable cros-garcon
    systemctl --user enable sommelier@0
    systemctl --user enable sommelier@1
    systemctl --user enable sommelier-x@0
    systemctl --user enable sommelier-x@1
    systemctl --user enable cros-sftp

    loginctl enable-linger name_here

    # Audio
    cp -rT /etc/skel/.config/pulse/ ~/.config/pulse

    exit
    ```


## 替换容器 {#替换容器}

完成上面的配置，直接在回到的 `termina` 虚拟机中完成容器替换

```bash
lxc move penguin{,-bak}
lxc move oS penguin
```

就，字面上的替换……

自此，使用 ChromeOS 自带终端启动 `penguin` 容器环境即可进入 openSUSE 的终端


## 测试/可选配置 {#测试-可选配置}

装个 gvim 看下桌面能不能拿到图标

```bash
sudo zypper in gvim
```

装个 opi，来方便的搜索/替换相关软件

```bash
sudo zypper in opi
opi codecs
```

装个 libnotify-tools，来测试通知

```bash
sudo zypper in libnotify-tools
notify-send "Hi!"
```

通过自带文件管理器可以共享目录到 Linux 环境，可以在 `/mnt/chromeos/` 目录下找到

装个 mpv，来放首歌

```bash
sudo zypper in mpv
mpv /mnt/chromeos/MyFiles/Downloads/a.mp3
```

也可以直接使用文件管理器通过 Linux 环境应用直接打开。


## 存在的问题 {#存在的问题}

目前就发现在自带文件管理器中看不到默认能看到的 Linux 环境用户目录文件，还不清楚原因。


## Reference {#reference}

在打包 `cros-container-guest-tools` 时有参考

-   <https://src.fedoraproject.org/rpms/cros-guest-tools>
-   <https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=cros-container-guest-tools-git>

在踩坑替换默认容器及相关配置时有参考

-   <https://wiki.archlinux.org/title/Chrome_OS_devices/Crostini>
