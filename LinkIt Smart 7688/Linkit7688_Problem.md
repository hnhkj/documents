---
title: "一点一滴分析LinkIt Smart 7688 问题汇总"
author: "hnhkj@163.com"
date: "2016年4月15日"
output: html_document
---

## 定义

**$ - 指定Ubuntu系统下命令**

**# - Openwrt下命令**

## 系统编译

#### .config文件

openwrt中，`make menuconfig`生成.config文件后，我们如何对.config中自定义的差异内容进行进行备份，方便移植到其它的系统中，这是一个问题。当然，有人说有很多简单的方法。但是这些都不是Openwrt开发着所希望看到的。对于Openwrt，开发团队创建了简单的工具`scripts/diffconfig.sh`。我们可以采用这个工具进行配置保存工作。

有一个简单的方法，生成diff文件，然后通过git进行操作，这样我们可以对我们自己的openwrt进行定制备份了。

1. 创建config diff文件

```
  $./scripts/diffconfig.sh > config.diff # write the changes to diffconfig`
```

2. 使用config diff文件

```
  $cp config.diff .config # write changes to .config
  $make defconfig # expand to full config
```

或者

```
  $cat config.diff >> .config # append changes to bottom of .config
  $make defconfig # apply changes
```

#### package编译（以Madplay为例）

1. madplay编译

全新编译
```
  $ make package/feeds/packages/madplay/{clean,compile,install} V=s
  $ make package/feeds/packages/madplay/{compile,install} V=s
```

重新编译

```
  $ make package/feeds/packages/madplay/compile V=s
```  

2. madplay安装

复制ipk文件到openwrt系统，然后通过opkg进行安装。

```
  $ scp bin/ramips/packages/packages/madplay-alsa_0.15.2b-4_ramips_24kec.ipk root@192.168.1.104:/tmp
```

安装madplay到openwrt

```
  # root@mylinkit:/tmp# opkg install madplay-alsa_0.15.2b-4_ramips_24kec.ipk
    Installing madplay-alsa (0.15.2b-4) to root...
    Configuring madplay-alsa.
```

3. package的Makefile


* PKG_NAME - The name of the package, as seen via menuconfig and ipkg
* PKG_VERSION - The upstream version number that we're downloading
* PKG_RELEASE - The version of this package Makefile
* PKG_LICENSE - The license(s) the package is available under, SPDX form.
* PKG_LICENSE_FILE- file containing the license text
* PKG_BUILD_DIR - Where to compile the package
* PKG_SOURCE - The filename of the original sources
* PKG_SOURCE_URL - Where to download the sources from (directory)
* PKG_MD5SUM - A checksum to validate the download
* PKG_CAT - How to decompress the sources (zcat, bzcat, unzip)
* PKG_BUILD_DEPENDS - Packages that need to be built before this package, but are not required at runtime. Uses the same syntax as DEPENDS below.
* PKG_INSTALL - Setting it to "1" will call the package's original "make install" with prefix set to PKG_INSTALL_DIR
* PKG_INSTALL_DIR - Where "make install" copies the compiled files
* PKG_FIXUP - See below
* PKG_SOURCE_PROTO - the protocol to use for fetching the sources (git, svn)
* PKG_REV - the svn revision to use, must be specified if proto is "svn"
* PKG_SOURCE_SUBDIR - must be specified if proto is "svn" or "git", e.g. "PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)"
* PKG_SOURCE_VERSION - must be specified if proto is "git", the commit hash to check out
* PKG_CONFIG_DEPENDS - specifies which config options depend on this package being selected
	
* SECTION - The type of package (currently unused) //包的类型
* CATEGORY - Which menu it appears in menuconfig //menuconfig的哪一个菜单显示
* TITLE - A short description of the package  //包的简短描述
* DESCRIPTION - (deprecated) A long description of the package  //报的一个长描述
* URL - Where to find the original software  // 那里找到源软件
* MAINTAINER - (required for new packages) Who to contact concerning the package  // 包的联系
* DEPENDS - (optional) Which packages must be built/installed before this package. See below for the syntax. // 哪些包需要必须先编译/安装
* PKGARCH - (optional) Set this to "all" to produce a package with "Architecture: all"
* USERID - (optional) a username:groupname pair to create at package installation time.

## 使用命令

#### SCP 文件传输

```
 scp ~/.ssh/id_dsa.pub root@192.168.1.1:/tmp
```

#### 环境变量显示

环境变量的相关信息，参考linux鸟歌私房菜上，P304。

#### 稍描wifi热点

```
  # iwinfo ra0 scan
  # time iwlist wlan0 scan | grep ESSID

  root@mylinkit:/tmp# iwinfo ra0 scan
  Cell 01 - Address: 6C:E8:73:AB:0C:96
            ESSID: "FAST_AB0C96"
            Mode: Master  Channel: 1
            Signal: -256 dBm  Quality: 10/100
            Encryption: WPA2 PSK (AES-OCB)

  Cell 02 - Address: C8:3A:35:29:F5:54
            ESSID: "wanghf"
            Mode: Master  Channel: 1
            Signal: -256 dBm  Quality: 7/100
            Encryption: WPA PSK (AES-OCB)

  Cell 03 - Address: 00:06:25:00:6E:72
            ESSID: "home"
            Mode: Master  Channel: 6
            Signal: -256 dBm  Quality: 81/100
            Encryption: WPA2 PSK (TKIP, AES-OCB)

  Cell 04 - Address: 8C:21:0A:41:D3:64
            ESSID: "wf"
            Mode: Master  Channel: 11
            Signal: -256 dBm  Quality: 0/100
            Encryption: WPA2 PSK (AES-OCB)
```

#### 重定向 0，1，2   >&1,>&2

0 是 < 的默认值，因此 < 与 0<是一样的;同理，> 与 1> 是一样的

  1. 标准输入(stdin):代码为0，使用<或<<；
  2. 标准输入(stdout):代码为1，使用>或>>；
  3. 标准错误输出(stderr)：代码为2，使用2>或2>>。
  0:Standard Input(STDIN)
  1:Standard Output(STDOUT)
  2:Standard Error Output(STDERR)  
  http://blog.csdn.net/thirstyblue/article/details/7974300
  http://www.cnblogs.com/Centaurus/archive/2013/05/25/3098256.html
  
>  #ls /dev 1>filename         //把命令的标准输出重新定向到一个文件filename  
>  #ls /dev >>filename         //把输出追加到filename文件的末尾  
>  #ls -qw  /dev  2>filename   //把标准错误重新定向到文件  
>  #ls /dev &>filename         //把标准输出和错误都定向到文件  

#### 垃圾黑洞 /dev/null

```
  $find /home -name .basehrc 2> /dev/null
```  
  
#### yes 命令

#### alsamixer,amixer 音量调节

* alsamixer是文本方式下的图形命令
* amixer是文本方式下的文本命令
  
参考文档：Linux鸟歌的私房菜  P359

获得当前喇叭音量值

```
# amixer cget numid=11,iface=MIXER,name='Speaker Playback Volume' | grep ': values' |sed 's/^.*values=//g' | sed 's/,.*$//g'
```

获得耳机音量值

```
# amixer cget numid=9,iface=MIXER,name='Headphone Playback Volume' | grep ': values' |sed 's/^.*values=//g' | sed 's/,.*$//g'
```

  获得播放音量值

```
# amixer cget numid=8,iface=MIXER,name='Playback Volume' | grep ': values' |sed 's/^.*values=//g' | sed 's/,.*$//g'
```  
  
#### du 查询磁盘空间使用情况

```
# du /
```

#### PID查询命令ps, pidof, pgrep

#### iwpriv

#### date

```
	root@mylinkit:/etc/config# date -help
	date: invalid option -- h
	BusyBox v1.23.2 (2016-01-20 23:54:03 CST) multi-call binary.

	Usage: date [OPTIONS] [+FMT] [TIME]

	Display time (using +FMT), or set time

        [-s,--set] TIME Set time to TIME
        -u,--utc        Work in UTC (don't convert to local time)
        -R,--rfc-2822   Output RFC-2822 compliant date string
        -I[SPEC]        Output ISO-8601 compliant date string
                        SPEC='date' (default) for date only,
                        'hours', 'minutes', or 'seconds' for date and
                        time to the indicated precision
        -r,--reference FILE     Display last modification time of FILE
        -d,--date TIME  Display TIME, not 'now'
        -D FMT          Use FMT for -d TIME conversion
        -k              Set Kernel timezone from localtime and exit

	Recognized TIME formats:
        hh:mm[:ss]
        [YYYY.]MM.DD-hh:mm[:ss]
        YYYY-MM-DD hh:mm[:ss]
        [[[[[YY]YY]MM]DD]hh]mm[.ss]
```
  
####  git

* git clone
* git reset HEAD^
* git reset HEAD^^
* git reset HEAD~3/1
* git reset -hard origin/master // 回退到远程最新版本
* git remote add github https://github.com/xxxx/openwrt.git
* git remote -v
* git checkout -b huang
* git branch
* git pull github huang:master    // 从远程github拉出huang分支到本地的master
* git push github huang:master    // 上传本地的huang分支到github远程的master

#### MTD

参考连接：<https://wiki.openwrt.org/doc/techref/mtd>

* 入如何写firmware到flash.

```
   # cd /tmp
   # wget http://www.example.org/original_firmware.bin 
   # mtd -r write /tmp/original_firmware.bin firmware
```

* 如何显示MTD状态

```
  root@mylinkit:/tmp# cat /proc/mtd
  dev:    size   erasesize  name
  mtd0: 00030000 00010000 "u-boot"
  mtd1: 00010000 00010000 "u-boot-env"
  mtd2: 00010000 00010000 "factory"
  mtd3: 00fb0000 00010000 "firmware"
  mtd4: 0011a791 00010000 "kernel"
  mtd5: 00e9586f 00010000 "rootfs"
  mtd6: 00100000 00010000 "rootfs_data"
```

* u-boot-env/factory

参考文档：linkit-smart-7688-feed\mtk-linkit\files\etc\uci-defaults\51_linkit_config

> Line30: MAC=$(dd bs=1 skip=7 count=3 if=/dev/mtd2 2>/dev/null | hexdump -v -n 3 -e '3/1 "%02X"'

* dd命令：/bin/dd

可以读取mtd2内的数据内容，mac地址

```
  # dd bs=1 skip=3 count=6 if=/dev/mtd2 2>/dev/null | hexdump 
```

* fw_printenv命令：/usr/sbin/fw_printenv

参考文档：linkit-smart-7688-feed\mtk-linkit\files\etc\init.d\linkit

> Line15: SEQ=`fw_printenv -n wifi_seq`

* 备份MTD2/factory信息

```
  # dd if=/dev/mtd2 of=/tmp/factory.bin
```

* 写factory.bin到mtd2

```
  # mtd2 write /tmp/factory.bin factory
```

注意：如果命令返回不能写入MTD2，可能是由于你的系统设定了禁止写该区域的权限。我们可以通过修改target/linux/ramips/dts/LINKIT7688.dts，注销禁止代码。这样就可以将数据写入到MTD2区域了。
  
## u-boot

#### build

```
  $git clone https://github.com/MediaTek-Labs/linkit-smart-7688-uboot.git
  $cd linkit-smart-7688-feed
  $make
```

#### modify

```
  $git checkout -b moh
  $make meuncofig
  $make
```

#### 修改uboot串口号

修改文件linkit-smart-7688-uboot\board\rt2880\serial.h

> line21: #define CFG_RT2880_CONSOLE	RT2880_UART3

#### 修改环境变量

* printenv

```
  MT7628 # setenv ipaddr 192.168.1.120
  MT7628 # setenv serverip 192.168.1.116
  MT7628 # saveenv
```

* setenv
* saveenv

#### linkit u-boot

* 烧录配置文件到uboot-env/lks7688.cfg

```
  $cat lks7688.cfg
  wifi_ssid=moh_app
  wifi_key=12345678
```  
插入u盘,按下wifi按钮，复位板子。等待wifi指示灯亮后，松开wifi按钮。uboot烧录配置到uboot-env

* 烧录firmware/lks7688.img

插入u盘，按下wifi按钮，复位板子，等待大约5秒（wifi指示灯亮然后灭掉），松开wifi按钮，uboot开始烧录firmware

* 烧录uboot/lks7688.ldr

插入u盘，按下wifi按钮，复位板子，等待大约20秒，松开wifi按钮，uboot更新uboot。

## shell

参考文档：Linux鸟歌的私房菜 P301
  
* 变量的引号''/""
  + 如果变量中包含有空格字符，这样变量字符需要用''/""
  + 如果用'',那么字符串中的变量$将保持为文本模式，不进行任何转换
  + 如果用"",那么字符串中的变量$将转换为变量内容。
  