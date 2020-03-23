---
title: scrcpy--首次独立OBS打包
date: 2019-04-23T15:42:00+08:00
categories: ForFun
tags: [Packaging,OBS]
description: 首次独立OBS打包记录（也跟个流水帐差不多
---
记首次独立OBS打包


<!--more-->

 UP：2019-04-24 13:18:46 星期三

---


# 缘由

软工项目（一个简单的扒每日一图设置壁纸的[Android程序](https://github.com/Rilzob/WallPaper/)）差不多完成 ~~（并没有~~，然后就是汇报了，考虑到自己手机一直保有图片存档，到时的缓存页面可能会好看一点，便提议用我手机展示。考虑到教室的投影设备，自己用的大蜥蜴，展示人也非自己，果然还是找个东西上教室电脑投屏比较好。然后就想到了之前『数字系统程序设计』作业，在提交的视频里面的骚操作（通过手机拍视频，得到板子反映，手机屏幕实时显示在电脑屏幕上，然后电脑上面录屏操作）所用到的一个开源软件[scrcpy](https://github.com/Genymobile/scrcpy)，去看了看，有 windows 版本，便准备了 32/64 位版本，然后考虑到自己数据线不太好使了，偶尔断线，去展示的人可能还不会操作重连 :joy: ，就决定利用吃灰的网卡走 adb_over_net ，写了个 bat 脚本，开个热点，手机连上并打开 adb_over_net，再来一个 bat 脚本执行一下 adb 连接操作和 scrcpy 运行操作，虚拟机，真机测试了一下感觉没啥问题。（~~还没展示，就是不确定教室电脑能不能管理员运行批处理脚本建热点~~ 教室电脑32位还行，还好提前准备好了，因为热点没有分享网络连接，出来一些问题，不过都无所谓了。

SO？这和 OBS 打包 scrcpy 有啥关系？

好吧，跑偏了，其实是准备用这个的时候，去看了看以前自己本地编译的版本，随手更新了一下，编译失败，去 http://software.opensuse.org 搜了一下，有不过没在 Factory 源里面，然后想起来自己还有个[自己的源](https://build.opensuse.org/project/show/home:zzndb)，于是就有了这个计划，把它放到自己的OBS源，统一管理:smile:，说不定还能方便他人？

然后又想起前几天，大蜥蜴 tg 群里和 dalao 扯打包自己只会参考别人 [spec 文件](https://zh.opensuse.org/openSUSE:Specfile_guidelines)，（自己其实也不想啊:joy:，还不是因为菜）就决定这次自己独立打个包试试。~~（然后昨晚上两点多才睡觉~~

以上，打包还算成功（至少能用:sweat_smile:），遂成此文记录。

#  开始

>> 好歹自己也打包过俩软件了，还是有点经验（雾

首先在自己本地的OBS项目目录建立新项目 [前期具体初始化操作参见](https://openbuildservice.org/help/manuals/obs-beginners-guide/)
```bash
osc mkpac scrcpy
```
然后在项目目录下扒下最新源代码，和这里必要的 prebuild `scrcpy-server-v1.8.jar`文件（就不考虑自己编译 server 了，还得 android sdk 
```bash
wget https://github.com/Genymobile/scrcpy/archive/v1.8.tar.gz
wget https://github.com/Genymobile/scrcpy/releases/download/v1.8/scrcpy-server-v1.8.jar
```
源代码改个标准名字
```bash
mv v1.8.tar.gz scrcpy-1.8.tar.gz
```
开写 spec 文件
```bash
vim scrcpy.spec # 默认加载了模板 spec 文件
```
写了写 `Name, Version, Summary, Licence, Url，Source`
从官方实验`Hardware`源里面，剽窃了`Group`信息`Hardware/Mobile`:satisfied:
> 记首次~~独立~~OBS打包

差不多这样：
```spec
Name:           scrcpy
Version:        1.8
Release:        0
Summary:        Display and control your Android device
# FIXME: Select a correct license from https://github.com/openSUSE/spec-cleaner#spdx-licenses
License:        Apache-2.0
# FIXME: use correct group, see "https://en.opensuse.org/openSUSE:Package_group_guidelines"
Group:          Hardware/Mobile
Url:            https://github.com/Genymobile/scrcpy
Source:         %{name}-%{version}.tar.gz   
Source1:        %{name}-server-v%{version}.jar
```
然后照 github 描述写了写`%description`部分

然后就是依赖了

## 依赖
>> 后面的编译测试中去掉了不需要的`ffmpeg-4，gcc`依赖（前者是 Leap 没有，后者是尝试去掉，发现完全没影响:joy:，应该毕竟有`meson`在了

然后它[编译指南](https://github.com/Genymobile/scrcpy/blob/master/BUILD.md)说还得 adb ？？
> You need adb. It is available in the Android SDK platform tools, or packaged in your distribution (android-adb-tools).

找了找

```bash
zse android
zse adb
```
没有！！
然后去 software.opensuse.org 搜了搜，没有！！
遂放弃 adb ，跳过
> 后面发现，竟然没啥影响。。。

然后说要 ffmepg 和 sdl2 然后随手一搜
```bash
zse --providers ffmpeg-4
zse --providers libSDL2-2_0-0
```
好家伙一堆。。。

看了看和大蜥蜴差不多的 Fedora 的依赖包名
`SDL2-devel ffms2-devel meson gcc make`

照着名字大概在源里找了找，尝试**写上**了`ffmpeg-4, meson, gcc, libSDL2-devel`

照着编译指南写了写`%build，%install`部分。

先本地试试再说
```bash
osc build --local-package openSUSE_Tumbleweed x86_64 scrcpy.spec
```
看了看报错
```bash
Dependency "libavformat" not found
```
再次在源里寻找，尝试**添加**了`ffmpeg-4-libavformat-devel`

再次尝试，看起来依赖问题没有了，报`scrcpy-server.jar`相关的错，去本地的编译目录看了看，还真没有我给的 server 文件，难道还得自己操作源文件？

## 编译安装
一顿操作之后...

好吧，看来源代码之类的会自己解压过去，**其他文件还得自己在`%prep`预编译阶段复制过去**
```spec
%prep
%setup -q
cp %{_sourcedir}/%{name}-server-v%{version}.jar .

%build
cp %{name}-server-v%{version}.jar server/scrcpy-server.jar
meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=./server/scrcpy-server.jar
cd x
ninja
```

开始在`%{install}`部分直接用编译指南给的`ninja -install`给了和我本地编译一样的错误，貌似是找不到规则，看了看编译指南的描述，貌似就安装了两个文件，看了看编译得到的东西也就一个可执行文件，考虑自己安装好了
```spec
%install
install -Dm 0755 x/app/scrcpy %{buildroot}%{_bindir}/%{name}
install -Dm 0644 server/scrcpy-server.jar %{buildroot}/usr/local/share/%{name}/scrcpy-server.jar
```
> 在这儿还有一个坑，我开始以为 server 文件放`/usr/share`也行和可执行文件类似，后面尝试发现它貌似写死的目录`/usr/local/share`，并不会自己去找。

## 文件处理
>> 上面安装的文件都得在这声明，遇到文件夹归属问题，得加上%dir 声明一下该文件夹

按照模板改了改`%license，和%doc`部分，添加了上面安装的两个文件，声明了对公共目录`/usr/local/share`的归属
```spec
%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
/usr/local/share/%{name}/scrcpy-server.jar

%dir /usr/local/share/%{name}
```
然后`%changelog`保持默认为空，毕竟有`.changes`文件

最后完整spec
```spec
# 省略前面 Copyright

Name:           scrcpy
Version:        1.8
Release:        0
Summary:        Display and control your Android device
# FIXME: Select a correct license from https://github.com/openSUSE/spec-cleaner#spdx-licenses
License:        Apache-2.0
# FIXME: use correct group, see "https://en.opensuse.org/openSUSE:Package_group_guidelines"
Group:          Hardware/Mobile
Url:            https://github.com/Genymobile/scrcpy
Source:         %{name}-%{version}.tar.gz   
Source1:        %{name}-server-v%{version}.jar
BuildRequires:  ffmpeg-4-libavformat-devel  
BuildRequires:  libSDL2-devel  
BuildRequires:  meson

%description
This application provides display and control of Android devices connected on 
USB. It does not require any root access

%prep
%setup -q
cp %{_sourcedir}/%{name}-server-v%{version}.jar . 

%build
cp %{name}-server-v%{version}.jar server/scrcpy-server.jar
meson x --buildtype release --strip -Db_lto=true -Dprebuilt_server=./server/scrcpy-server.jar
cd x
ninja

%install
install -Dm 0755 x/app/scrcpy %{buildroot}%{_bindir}/%{name}
install -Dm 0644 server/scrcpy-server.jar %{buildroot}/usr/local/share/%{name}/scrcpy-server.jar

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
/usr/local/share/%{name}/scrcpy-server.jar

%dir /usr/local/share/%{name}

%changelog
```

然后写 `.change`文件，提交编译
```bash
osc ar # auto add or remove file
osc vc # change file
osc ci # commit
```

![2019-04-23_10-58.png](/images/2019/04/417551773.png)

yeah！

# 总结
>> 其实是这个包打包还算简单，毕竟纯 cli ，就两文件。

通过这次的独立~~（严格来说不能算~~的OBS打包，还是收获挺多的
1. 编译安装过程的非源代码文件处理得手动做
2. get到一些默认的 macro 宏（巩固？
    `%{buildroot}=/builddir/SOURCE/name/`
    `%{_sourcedir}=/builddir/SOURCE/`
    `%{_builddir}=/builddir/`
    `%{_datadir}=/usr/share/`
    `%{_bindir}=/usr/bin`
    [常见RPM宏](https://zh.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros)
3. 安装的文件都得在`%{file}`部分声明
4. 手动安装的文件权限问题（一开始给可执行文件上了`0644`:joy:

然后是我打包的这个包的[地址](https://build.opensuse.org/package/show/home:zzndb/scrcpy)，自己在 TW 测试过没啥问题，如果有有*投屏，远程控制* 的需求的用大蜥蜴的 Android 用户，又不想自己编译，又苦于默认源里没有，欢迎使用我的源:kissing_heart:，已 watch 该项目的 release 应该会保持更新。~~（这应该用得有点意思~~

done！
