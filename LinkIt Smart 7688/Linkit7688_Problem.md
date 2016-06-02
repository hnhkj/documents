---
title: "一点一滴分析LinkIt Smart 7688 问题汇总"
author: "hnhkj@163.com"
date: "2016年6月2日"
output: html_document
---

[TOC]

* [1.系统编译](#1)
    * [1.1 .config文件](#1.1)
        * [1.1.1 如何创建config diff文件](#1.1.1)
        * [1.1.2 如何使用config diff文件](#1.1.2)
    * [1.2 编译](#1.2)
        * [1.2.1 linux编译](#1.2.1)
        * [1.2.2 package编译（以Madplay为例）](#1.2.2)        
    * [1.3 dts文件修改](#1.3)
        * [1.3.1 按钮相关修改](#1.3.1)
        * [1.3.2 SD卡检测引脚电平修改](#1.3.2)
    * [1.4 package创建](#1.4)
    
* [2.系统配置](#2) 
    * [MTD操作](#2.1)
    * [用SD卡扩展空间](#2.2)
    * [ifconfig 相关参数](#2.3)
    * [network 配置](#2.4)

* [3. openwrt application](#3)
    * [3. opkg](#3.1)
* [4. linux application](#4)
    * [4.1 git](#4.1)
    
    
* [附录](#附录)


## 定义

**$ - 指定Ubuntu系统下命令**

**# - Openwrt下命令**



<h4 id="1"></h4>
## 1. 系统编译

<h4 id="1.1"></h4>
#### 1.1 .config文件

openwrt中，`make menuconfig`生成.config文件后，我们如何对.config中自定义的差异内容进行进行备份，方便移植到其它的系统中，这是一个问题。当然，有人说有很多简单的方法。但是这些都不是Openwrt开发着所希望看到的。对于Openwrt，开发团队创建了简单的工具scripts/diffconfig.sh`。我们可以采用这个工具进行配置保存工作。

有一个简单的方法，生成diff文件，然后通过git进行操作，这样我们可以对我们自己的openwrt进行定制备份了。

<h4 id="1.1.1"></h4>
**1.1.1 如何创建config diff文件**

```
  $./scripts/diffconfig.sh > config.diff # write the changes to diffconfig`
```

<h4 id="1.1.2"></h4>
**1.1.2 如何使用config diff文件**

```
  $cp config.diff .config # write changes to .config
  $make defconfig # expand to full config
```

或者

```
  $cat config.diff >> .config # append changes to bottom of .config
  $make defconfig # apply changes
```

<h4 id="1.2"></h4>
#### 1.2 编译

系统编译很简单，直接在系统目录下运行`make`命令就可以了，如果想查看输出信息，可以在`make`后面增加`V=s`。如果是多核系统，可以在后面再增加`j=2`或其它数字，这代表同时有多个线程同时运行。这样可以提高编译速度。我的系统是单核的，我验证了一下没有任何改善。多核系统可以测试一下。
```
 $ make V=99
```

<h4 id="1.2.1"></h4>
#### 1.2.1 linux核心编译

如果我们仅仅是想对linux核心包进行编译，可以采用下面的命令来进行。

``` 
 $ make target/linux/{clean,prepare} V=s QUILT=1
```


<h4 id="1.2.2"></h4>
#### 1.2.2 package编译（以Madplay为例）

**全新编译madplay**
```
  $ make package/feeds/packages/madplay/{clean,compile,install} V=s
  $ make package/feeds/packages/madplay/{compile,install} V=s
```

**重新编译madplay**

```
$ make package/feeds/packages/madplay/compile V=s
```

<h4 id="1.2.3"></h4>
#### 1.2.3 package安装(以Madplay为例)

**madplay安装**

复制ipk文件到openwrt系统(采用scp命令)，然后通过opkg进行安装。

```
  $ scp bin/ramips/packages/packages/madplay-alsa_0.15.2b-4_ramips_24kec.ipk root@192.168.1.104:/tmp
```

安装madplay到openwrt

```
  # root@mylinkit:/tmp# opkg install madplay-alsa_0.15.2b-4_ramips_24kec.ipk
    Installing madplay-alsa (0.15.2b-4) to root...
    Configuring madplay-alsa.
```

<h4 id="1.3"></h4>
#### 1.3 dts文件修改

<h4 id="1.3.1"></h4>
**1.3.1 按钮相关修改**

MT7688按钮一组为32个，所以GPIO0组对应GPIO0-PIO32，GPIO1组对应GPIO32以上的引脚。

参考连接<https://wiki.openwrt.org/doc/howto/hardware.button?s[]=button&s[]=hotplug>

```
	gpio-keys-polled {
		compatible = "gpio-keys-polled";
		#address-cells = <1>;
		#size-cells = <0>;
		poll-interval = <20>;
		wps {
			label = "wps";
			gpios = <&gpio1 6 1>;     // GPIO38 wifi button 
			linux,code = <0x211>;
		};
		key_playpause {
			label = "key_playpause";
			gpios = <&gpio0 15 1>;		// GPIO15-KEY_PLAY/Pause(S5)
			linux,code = <164>;
		};
		key_volumeup {
			label = "key_volumeup";
			gpios = <&gpio0 17 1>;		//GPIO17-KEY_VOL+(S7)
			linux,code = <115>;
		};
		key_volumedown {
			label = "key_volumedown";
			gpios = <&gpio0 18 1>;		//GPIO18-KEY_VOL-(S8)
			linux,code = <114>;
		};
		key_next {
			label = "key_next";
			gpios = <&gpio0 16 1>;		//GPIO16-KEY_NEXT(S6)
			linux,code = <0x197>;
		};
		key_previous {
			label = "key_previous";
			gpios = <&gpio0 14 1>;		//GPIO14-KEY_PRE(S4)
			linux,code = <0x19c>;
		};
	};
	
```
<h4 id="1.3.2"></h4>
**1.3.2 SD卡检测引脚电平修改**

LinkIt smart7688的SD卡检测，默认是高电平。但是普通的SD卡是低电平。所以，要对dts进行修改。使用下面命令：

```
$ vi target/linux/ramips/dts/LINKIT7688.dts
```

修改前：
```
   	sdhci@10130000 {
		status = "okay";
		mediatek,cd-high;
//		mediatek,cd-poll;
	};
```
修改后：
```
		sdhci@10130000 {
		status = "okay";
		mediatek,cd-low;
//		mediatek,cd-poll;
	};
```

<h4 id="1.4"></h4>
#### 1.4 package创建

**package的Makefile**

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


<h2 id="2"></h2>
## 2. 系统配置

<h4 id="2.1"></h4>
#### 2.1 MTD

参考连接：<https://wiki.openwrt.org/doc/techref/mtd>

<h4 id="2.1.1"></h4>
* 2.1.1 如何显示MTD状态

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

<h4 id="2.1.2"></h4>
* 2.1.2 dd命令：/bin/dd
  读取mtd2内的数据内容，mac地址

```
  # dd bs=1 skip=3 count=6 if=/dev/mtd2 2>/dev/null | hexdump 
```

<h4 id="2.1.3"></h4>
* 2.1.3 入如何写firmware到flash.

```
   # cd /tmp
   # wget http://www.example.org/original_firmware.bin 
   # mtd -r write /tmp/original_firmware.bin firmware
```

<h4 id="2.1.4"></h4>
* 2.1.4 备份MTD2/factory信息

```
  # dd if=/dev/mtd2 of=/tmp/factory.bin
```

<h4 id="2.1.5"></h4>
* 2.1.5 写factory.bin到mtd2

```
  # mtd2 write /tmp/factory.bin factory
```

*注意：*如果命令返回不能写入MTD2，可能是由于你的系统设定了禁止写该区域的权限。我们可以通过修改`target/linux/ramips/dts/LINKIT7688.dts`，注销禁止代码。这样就可以将数据写入到MTD2区域了。

* u-boot-env/factory

参考文档：linkit-smart-7688-feed\mtk-linkit\files\etc\uci-defaults\51_linkit_config

Line30:

> MAC=$(dd bs=1 skip=7 count=3 if=/dev/mtd2 2>/dev/null | hexdump -v -n 3 -e '3/1 "%02X"'


* fw_printenv命令：/usr/sbin/fw_printenv

参考文档：linkit-smart-7688-feed\mtk-linkit\files\etc\init.d\linkit

Line15:

>  SEQ=`fw_printenv -n wifi_seq`




<h4 id="2.2"></h4>
#### 2.2 用SD卡扩展空间(未验证)


参考: <http://labs.mediatek.com/forums/posts/list/4121.page>

```
Yes!you can mount tf card as overlay 
1.install block-mount e2fsprogs kmod-fs-ext4 
2.mkfs.ext4 /dev/mmcblk0 
3.block detect > /etc/config/fstab 
4.vi etc/config/fstab 
modify option 'target' '/overlay' 
modify option 'enable' '1' 
5.reboot,use df -h check 
```


<h4 id="2.3"></h4>
#### [ifconfig 相关参数]

**状态：Ethernet0 连接PC，Wifi连接Router (状态非常好)**

```
ifconfig
apcli0    Link encap:Ethernet  HWaddr 9E:65:F9:0B:18:55
          inet addr:192.168.1.104  Bcast:192.168.1.255  Mask:255.255.255.0
          inet6 addr: fe80::9c65:f9ff:fe0b:1855/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

br-lan    Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          inet addr:192.168.100.1  Bcast:192.168.100.255  Mask:255.255.255.0
          inet6 addr: fe80::9e65:f9ff:fe1b:1027/64 Scope:Link
          inet6 addr: fdef:dd3c:f1e1::1/60 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:478 errors:0 dropped:0 overruns:0 frame:0
          TX packets:340 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:45279 (44.2 KiB)  TX bytes:46562 (45.4 KiB)

eth0      Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:525 errors:0 dropped:0 overruns:0 frame:0
          TX packets:307 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:70666 (69.0 KiB)  TX bytes:46599 (45.5 KiB)
          Interrupt:5

eth0.1    Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          inet6 addr: fe80::9e65:f9ff:fe1b:1027/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:5911 (5.7 KiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:1269 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1269 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:88230 (86.1 KiB)  TX bytes:88230 (86.1 KiB)

ra0       Link encap:Ethernet  HWaddr 9C:65:F9:1B:18:55
          inet6 addr: fe80::9e65:f9ff:fe1b:1855/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:11176 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2457 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2248608 (2.1 MiB)  TX bytes:42335 (41.3 KiB)
          Interrupt:6
```


<h4 id="2.4"></h4>
#### 2.4 network 配置

```
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'fd01:80d1:1f98::/48'

config interface 'lan'
    option ifname 'eth0'
    option force_link '1'
    option type 'bridge'
    option proto 'static'
    option netmask '255.255.255.0'
    option ip6assign '60'
    option ipaddr '192.168.100.1'
    option macaddr '00:0c:43:e1:76:2a'

config switch
    option name 'switch0'
    option reset '1'
    option enable_vlan '0'

config interface 'wan'
    option proto 'dhcp'
```



<h4 id="3"></h4>    
## 3. openwrt application

<h4 id="3.1"></h4>
#### 3. opkg

<h4 id="4"></h4>    
## 4. linux application

<h4 id="4.1"></h4>    
#### 4.1 git
     
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
* git merge

```
  git pull origon master    // 从远程服务器更新master分支
  git checkout IR077H       // 切换到IR077H分支
  git merge Master          // 合并Master分支到当前分支
```
 


* 状态：Ethernet 0连接路由器，Wifi配置home。

```
root@mylinkit:/etc/config# ifconfig
apcli0    Link encap:Ethernet  HWaddr 9E:65:F9:0B:18:55
          inet addr:192.168.100.169  Bcast:192.168.100.255  Mask:255.255.255.0
          inet6 addr: fe80::9c65:f9ff:fe0b:1855/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

br-lan    Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          inet addr:192.168.100.1  Bcast:192.168.100.255  Mask:255.255.255.0
          inet6 addr: fe80::9e65:f9ff:fe1b:1027/64 Scope:Link
          inet6 addr: fdef:dd3c:f1e1::1/60 Scope:Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:98 errors:0 dropped:0 overruns:0 frame:0
          TX packets:167 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:12185 (11.8 KiB)  TX bytes:23247 (22.7 KiB)

eth0      Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:107 errors:0 dropped:0 overruns:0 frame:0
          TX packets:143 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:14557 (14.2 KiB)  TX bytes:24058 (23.4 KiB)
          Interrupt:5

eth0.1    Link encap:Ethernet  HWaddr 9C:65:F9:1B:10:27
          inet6 addr: fe80::9e65:f9ff:fe1b:1027/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:5911 (5.7 KiB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:1012 errors:0 dropped:0 overruns:0 frame:0
          TX packets:1012 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:70360 (68.7 KiB)  TX bytes:70360 (68.7 KiB)

ra0       Link encap:Ethernet  HWaddr 9C:65:F9:1B:18:55
          inet6 addr: fe80::9e65:f9ff:fe1b:1855/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:6429 errors:0 dropped:0 overruns:0 frame:0
          TX packets:2163 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1289015 (1.2 MiB)  TX bytes:8606 (8.4 KiB)
          Interrupt:6
```




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
  

<h4 id="4.1"></h4>     
## Git工具


#### git clone https://xxx.xxx.git

#### 从服务器更新本地文档

```
$ git pull origin master
```

### 分支管理

#### 创建分支并切换到分支

```
$ git checkout -b moh
```

#### 分支切换

```
$ git checkout moh
```

#### 分支合并 //合并master到moh分支

```  
$ git checkout moh  
$ git merge master  
```




#### 图形界面GitK

```
$ gitk
```

gitk是linux下git自带的一个图形显示工具。可以使用这个工具在图形模式下察看详细的log文件等信息。
  