1. 系统编译
 1.1. 如何备份.config文件
  1.1.1 创建config diff文件
  1.1.2 使用config diff文件
 1.2. 如何生成patches文件
 1.3 dts文件修改
  1.3.1 增加按钮
  1.3.2 linux,code=<0x19c>
  1.3.3 gpio debug 
 1.4 系统编译
 1.5 package编译
  1.5.1 madplay编译
  1.5.2 madplay安装
 1.6 init.d/rc.d开机自动运行
 
2. 命令
 2.1 scp命令
 2.2 环境变量显示
 2.3 扫描wifi热点
 2.4 WLAN配置
 2.5 console/tty/pts/shm
  2.5.1 console
  2.5.2 tty
  2.5.3 pts
  2.5.4 shm
 2.6 重定向 0，1，2   >&1,>&2
 2.7 /dev/null
 2.8 将正确和错误的信息都写入同一个文件中
 2.9 yes 命令
 2.10 expect 或者 EOF 
 2.11 alsamixer,amixer 音量调节
 2.12 du 查询磁盘空间使用情况
 2.13 PID查询命令ps, pidof, pgrep
 2.14 iwpriv
 2.15 date
 2.16 grep,sed,cut
 2.17 wait
 
 
3. MOH项目修改
 3.1 linkit应用
  3.1.1 减少firmware体积
 3.2 Micro-SD卡检测修改，dts文件修改
 3.3 WM8960 驱动修改
  3.3.1 quilt patch
  3.3.2 操作步骤
 3.4 /etc/config/network 修改
 3.5 按钮操作
  3.5.1 采用procd和gpio-button-hotplug采样按钮
  3.5.2 脚本 GPIO 控制
 3.6 SD卡不能写入

 
4. madplay
 4.1 播放网络音频
 4.2 madplay系统控制方式
 4.3 madplay管道控制方式 FIFO
 4.4 madplay音量控制
 

5. MTD使用
 5.1 入如何写firmware到flash.
 5.2 如何显示MTD状态
 5.3 u-boot-env/factory
 5.4 fw_printenv命令
 5.5 备份MTD2/factory信息
 5.6 写factory.bin到mtd2

6. u-boot
 6.1 build
 6.2 modify
  6.2.1 修改uboot串口号
 6.3 修改环境变量
  6.3.1 printenv
  6.3.2 setenv
  6.3.3 saveenv
 6.4 linkit uboot
  6.4.1  烧录配置文件到uboot-env/lks7688.cfg
  6.4.2, 烧录firmware/lks7688.img
  6.4.3, 烧录uboot/lks7688.ldr
  
7 shell
7.1 变量的引号''/""

8. openwrt web
8.1 luci

9. web编程
9.1 React
9.2 jQuery/easyUI