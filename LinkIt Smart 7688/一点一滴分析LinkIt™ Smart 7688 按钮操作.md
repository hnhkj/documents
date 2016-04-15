---
title: "一点一滴分析LinkIt™ Smart 7688 按钮操作"
author: "hnhkj@163.com"
date: "2016年4月12日"
output: html_document
---

1. 采用procd和gpio-button-hotplug采样按钮
---------------------------------

   在openwrt中如何进行按钮操作，有多中方法。我认为一种方法比较easy。参考1.3。
   该方法采用了gpio-button-hotplug (openwrt/package/kernel/gpio-button-hotplug)模块进行控制。
具体的步骤：

 - 修改 target/linux/ramips/dts/LINKIT7688.dts. 将相关的按钮配置成gpio-button-hotplug认可的按钮。
 -  编译系统
 - 参考https://wiki.openwrt.org/doc/howto/hardware.button?s[]=button&s[]=hotplug文档进行操作。
 - So easy。

如果采用procd方式，需要创建脚本到 /etc/rc.button/ 目录。每个脚本对应指定的按钮。如果采用gpio-button-hotplug，需要创建脚本到 /etc/hotplug.d/button/00-button，该脚本处理按钮信息。参考openwrt网站信息。

```
root@mylinkit:/# cat /sys/kernel/debug/gpio
GPIOs 0-31, platform/10000600.gpio, 10000600.gpio:
gpio-11  (bootstrap           ) out lo
gpio-14  (BTN_0               ) in  hi
gpio-15  (BTN_1               ) in  hi
gpio-16  (BTN_2               ) in  hi
gpio-17  (BNT_3               ) in  hi
gpio-18  (BTN_4               ) in  hi
gpio-19  (BTN_5               ) in  hi

GPIOs 32-63, platform/10000600.gpio, 10000600.gpio:
gpio-38  (reset               ) in  hi

GPIOs 64-95, platform/10000600.gpio, 10000600.gpio:

GPIOs 127-127, platform/gpio-wifi, gpio-wifi:
gpio-127 (mediatek:orange:wifi) out ?
```


3.5.2 脚本 GPIO 控制
  https://wiki.openwrt.org/doc/howto/hardware.button
  https://wiki.openwrt.org/doc/hardware/port.gpio?s[]=kmod&s[]=leds&s[]=gpio
  https://wiki.openwrt.org/doc/howto/hardware.button#preliminary.steps

 http://wiki.wrtnode.cc/index.php?title=用户空间gpio的调用
 1. GPIO应用层控制
  1.1 GPIO39引脚控制LED
  1.1.1 导出GPIO39引脚
  root@mylinkit:/sys/class/gpio# echo "39">export
  root@mylinkit:/sys/class/gpio# ls
  export       gpio39       gpiochip0    gpiochip127  gpiochip32   gpiochip64   unexport
  1.1.2 定义GPIO39输出
  root@mylinkit:/sys/class/gpio# cd gpio39
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# ls
  active_low  device      direction   edge        subsystem   uevent      value
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# cat direction
  in
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# echo "out" >direction
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# cat direction
  out
  1.1.3 修改GPIO39输出电平
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# cat value
  0
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# echo "1" > value
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio39# cat value
  1
  1.2 检测一个按钮输入
  1.2.1 导出GPIO
  root@mylinkit:/sys/class/gpio# echo "16">export
  root@mylinkit:/sys/class/gpio# ls
  export       gpio16       gpiochip0    gpiochip127  gpiochip32   gpiochip64   unexport
  root@mylinkit:/sys/class/gpio# cd gpio16
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# ls
  active_low  device      direction   edge        subsystem   uevent      value
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16#
  1.2.2 定义GPIO39输入
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# cat direction
  in
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# echo "in">direction
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# cat direction
  in
  1.2.3 检测按钮状态 高电平/低电平
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# cat value
  1
  root@mylinkit:/sys/devices/10000000.palmbus/10000600.gpio/gpio/gpio16# cat value
  0
