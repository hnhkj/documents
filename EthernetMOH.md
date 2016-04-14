---
title: "Ethernet Player设计"
author: "hnhkj@163.com"
date: "2016年4月14日"
output: html_document
---

## 设计导入
现在存在的 MOHPlayer是基于mp3播放芯片(WT2000)的设计方案。该方案采用mp3芯片+mcu的方式实现了MOHPlayer的实时播放功能。

由于当前物联网的快速发展，市面上出现了很多新的性能强大的控制芯片，MediaTek [MT7688](http://www.mediatek.com/en/products/connectivity/wifi/home-network/wifi-ap/mt7688ka/)
就是其中的一款。该芯片具有wifi接口和高的性能。能够满足大多数设计的需求。另外，该芯片可以采用[Openwrt](https://openwrt.org/)系统，MediaTek现在持续对芯片提供技术支持。这些都方便了我们快速应用该芯片。这也是我采用这款芯片的主要原因。

客户要求信息(email:2016/4/1 10:34)：

> Config needs to allow for:  
> · MOH only with wifi, LAN and 4G with Usb load option, minimum Flash  
> · Music only with option to add soyo module  
> · MOH and Music (4G will not be used in this combination)  

> So:  
> · Soyo is add-in module (check we can add 2.4GHz and 5,8GHz as options)  
> · Codec 1 output can go to MOH output or Music (Audio and Soyo)  
> · Codec 2 is optional add-on  

## 硬件设计

![image001](img/image001.jpg)


**图1 系统框图**

### 系统功能分解

系统**接口分类**（参考图1）：

* MOH接口
* Music接口
* wifi接口
* LAN接口
* 4G接口
* soyo module接口

该系统按**功能分类**的话，分为下面几部分。各个功能的具体功能要求如下。

* MOH功能
  + MOH function
  + wifi
  + LAN
  + 4G
* Music功能
  + Music function
  + wifi
  + LAN
  + 4G
  + soyo module
* MOH和music功能
  + MOH function
  + Music function
  + wifi
  + LAN
  + soyo module

不同功能的实现，采用不同的模块进行组合。因而，硬件设计的时候必须要考虑各个接口之间的配合如何衔接。如何能够更理想的实现硬件方便组合。

在整个设计规划中，主板是核心部件。wifi接口，LAN接口，MOH接口，Music接口是已经定型的借口。只需要合理安排它们的布局就可以实现它们的功能。对于soyo模块和4G模块，目前，还存在一些争议。

### 主要模块

##### 4G模块

目前市面上的4G模块，分为两种制式：TD-LTE(LTE TDD)和FD-LTE(LTE FDD)。这两种制式有些许差别，从而影响到了它们的价格。

* **[TD-LTE（LTE TDD）](https://zh.wikipedia.org/wiki/%E5%88%86%E6%97%B6%E9%95%BF%E6%9C%9F%E6%BC%94%E8%BF%9B)：** 分时长期演进（英语：Long Term Evolution，Time-Division Duplex ，简称“LTE-TDD”）是基于3GPP长期演进技术（英语：LTE）的一种通讯技术与标准，属于LTE的一个分支。该技术由上海贝尔、诺基亚西门子通信、大唐电信、华为技术、中兴通讯、中国移动、高通、ST-Ericsson等业者共同开发。
***该标准是中国主导的LTE标准。***
* **[FD-LTE（LTE FDD）](http://baike.baidu.com/item/fdd-lte)：**FDD（频分双工）是该技术支持的两种双工模式之一，应用FDD（频分双工）式的LTE即为FDD-LTE。作为LTE的需求，TD系统的演进与FDD系统的演进是同步进行的。绝大多数企业对LTE标准的贡献可等同用于FDD和TD模式。

经过我的查询，目前市面上存在的4G模块多单制式的，价格适中。如果采用全网通模块，价格成本偏高，价位在300元左右。作为这一块来讲，我考虑采用通用的接口。对于不同的客户，针对客户地区的制式采用不同的模块。这样能够给客户大的选择权。所以，我尽量采用大多模块采用的通用接口来设计。经过对各个厂家的模块对比，决定采用mini-PCI express接口是一个不错的选择。大多数模块支持该接口，这样也方便了客户更换和采购。

* Huaiwei 4G模块 - <http://consumer.huawei.com/en/solutions/m2m-solutions/products/index.htm>
* ZTE 4G模块 - <http://www.ztewelink.com/cn/products/module/>

#### soyo模块

目前，Soyo的模块有两种：

* SOYO-WM24G02 - 该模块采用2.4G频段进行音品数据传输，可以通过I/O和I2C端口对其进行控制。
* SOYO-WM58G01 - 该模块采用5.8G频段进行音品数据传输，可以通过I/O，I2C，Uart端口对其进行控制。目前，控制功能不太完善。


### 接口设计

#### MT7688A 引脚

|Pin|GPIO|Function|Other Function|Type|Description|Device|
|---|----|------|--------|---|---|---|
||||||||
|16|GPIO0|__I2S_SDI__||||Codec|
|17|GPIO1|__I2S_SDO__||||Codec|
|18|GPIO2|__I2S_WS__||||Codec|
|19|GPIO3|__I2S_CLK__||||Codec|
|20|GPIO4|__I2C_SCLK__||||Codec|
|21|GPIO5|__I2C_SD__||||Codec|
||||||||
|24|GPIO6|SPI_CS1||||SPI|
|25|GPIO7|SPI_CLK||||SPI|
|26|_GPIO9_|SPI_MISO||||SPI|
|27|_GPIO8_|SPI_MOSI||||SPI|
|28|GPIO10|SPI_CS0||||SPI|
|29|GPIO11|GPIO0|||||
|30|GPIO12|__UART_TXD0__||||UART0|
|31|GPIO13|__UART_RXD0__||||UART0|
||||||||
|33||__MDI_RP_P0__||||Eth0|
|34||__MDI_RN_P0__||||Eth0|
|35||__MDI_TP_P0__||||Eth0|
|36||__MDI_TN_P0__||||Eth0|
||||||||
|40|GPIO14|MDI_TP_P1||||Eth1|
|42|GPIO15|MDI_TN_P1||||Eth1|
|43|GPIO16|MDI_RP_P1||||Eth1|
|44|GPIO17|MDI_RN_P1||||Eth1|
|45|GPIO18|MDI_RP_P2||||PWM0||
|46|GPIO19|MDI_RN_P2||||PWM1||
|47|GPIO20|MDI_TP_P2|PWM2/__UART_TXD2__|||console|
|48|GPIO21|MDI_TN_P2|PWM3/__UART_RXD2__|||console|
|49|GPIO22|MDI_TP_P3|__SD_WP__|||*Low level enable write function|
|50|GPIO23|MDI_TN_P3|__SD_CD__|||Micro SD|
|51|GPIO24|MDI_RP_P3|__SD_D1__|||Micro SD|
|52|GPIO25|MDI_RN_P3|__SD_D0__|||Micro SD|
||||||||
|54|GPIO26|MDI_RP_P4|__SD_CLK__|||Micro SD|
|55|GPIO27|MDI_RN_P4|__SD_CMD__|||Micro SD|
|56|GPIO28|MDI_TP_P4|__SD_D3__|||Micro SD|
|57|GPIO29|MDI_TN_P4|__SD_D2__|||Micro SD|
||||||||
|61||__USB_DP__||I/O|USB Port0 data pin Data+|USB Hub|
|62||__USB_DM__||I/O|USB Port0 data pin Data-|USB Hub|
||||||||
|126||__PCIE_TXN0__||I/O|PCIe0 differential transmit TX-|mini PCIE|
|127||__PCIE_TXP0__||I/O|PCIe0 differential transmit TX+|mini PCIE|
|128||PCIE_IO_VSS||P|PCIE PHY Ground Pin||
|129||__PCIE_RXP0__||I/O|PCIe0 differential receiver RX+|mini PCIE|
|130||__PCIE_RXN0__||I/O|PCIe0 differential receiver RX-|mini PCIE|
|131||AVDD12_PCIE||P|1.2V PCIE PHY digital power supply||
|132||__PCIE_CKN0__||I/O|External reference clock output (negative)|mini PCIE|
|133||__PCIE_CKP0__||I/O|External reference clock output (positive)|mini PCIE|
|134||AVDD33_PCIE||P|3.3V USB PHY analog power supply||
|135|GPIO36|PERST_N||O,IPD|PCIe device reset|mini PCIE|
|136|GPIO37|__ERF_CLK0__||||Codec|
|137|GPIO38|WDT_RST_N||O|Watchdog timeout reset|WIFI Button|
|138||__PORST_N__||I,IPU|Power on reset|MPU Button|
|139|GPIO39|EPHY_LED4_N|JTRST_N|||Button|
|140|GPIO40|EPHY_LED3_N|JTCLK|||Button|
|141|GPIO41|EPHY_LED2_N|JTMS|||Button|
|142|GPIO42|__EPHY_LED1_N__|JTDI|||Eth1 LED|
|143|GPIO43|__EPHY_LED0_N__|JTDO|||Eth0 LED|
|144|GPIO44|__WLED_N__||||Wirelss LAN LED|
||||||||
|147|GPIO45|__UART_TXD1__||||mini PCIE/Soyo module|
|148|GPIO46|__UART_RXD1__||||mini PCIE/Soyou module|
||||||||



#### PCI Express Mini 接口设计

MT7688A具有一组的PCI-E接口。因而，我们能够设计一款适合于MT7688A的PCI-E接口。通过该接口，我们可以方便的扩展3G/4G模块功能。并且，也可以在将来扩展其它的模快。这是一个非常方便的接口。所以，我打算利用这个接口，来实现我们的3G/4G功能。

我采用的是标准的PCI Express Mini Card座，尽量将所有的电气性能向该标准靠拢。我们可以在后面的网址下载到PCI Express Mini卡电气规格书（PCI Express® Mini Card Electromechanical Specification）  <http://www.mod-book.ru/forum/attachment.php?attachmentid=1035>。

对于**Mini PCI express**插座，我选用的是Molex公司的[67910](http://www.molex.com/molex/products/listview.jsp?query=67910&path=cHome%23%23-1%23%23-1~~ncEDGECARDCONNECTO%23%230%23%23d&offset=0&autoNav=1&sType=s&filter=boo&fs=&channel=Products)，该插座按照标准设计的。我们不用理会兼容问题。

![image002](img/image002.png)


**mini PCI-E接口**

|Pin|Mame||Pin|Name||
|---|---|---|---|---|---|
|51|~~Reserved~~||51|+3.3Vaux||
|49|~~Reserved~~||50|GND||
|47|~~Reserved~~||48|+1.5V||
|45|~~Reserved~~||46|LED_WPAN#||
|43|GND||44|LED_WLAN#||
|41|+3.3VAux||42|LED_WWAN#||
|39|+3.3VAux||40|GND||
|37|GND||38|__USB_D+__|4G|
|35|GND||36|__USB_D-__|4G|
|33|PETp0||34|GND||
|31|PETn0||32|~~SMB_DATA~~||
|29|GND||30|~~SMB_CLK~~||
|27|GND||28|+1.5V||
|25|PERp0||26|GND||
|23|PERn0||24|+3.3Vaux||
|21|GND||22|PERST#||
|19|~~Reserved~~||20|W_DISABLE#||
||~~(UIM_C4)~~|||||
|17|~~Reserved~~||18|GND||
||~~(UIM_C8)~~||18|GND||
|||Mechanical key||||
|15|GND||16|UIM_VPP||
|13|REFCLK+||14|__UIM_RESET__|sim card|
|11|REFCLK-||12|__UIM_CLK__|sim card|
|9|GND||10|__UIM_DATA__|sim card|
|7|CLKREQ#||8|__UIM_PWR__|sim card|
|5|COEX2||6|1.5V||
|3|COEX1||4|GND||
|1|WAKE#||2|3.3Vaux||


为了尽快实现我的想法，我希望能够有一块MT7688A的相关产品，能够具有Mini PCI-E接口。这样可以先进行一些测试，避免在硬件电路中出现差错。我查询了不少相关的信息。目前的情况来看双龙公司的开发板具备了Mini PCI-E接口功能。另外，我查询到MT7620A也有相关的产品具备3G/4G功能，也就是说具有mini PCI-E接口。

**NetComm 4GM3W-01**  
<http://www.netcommwireless.com/product/4g/4gm3w>  
**Aztech WL580E**  
<ftp://ftp.aztech.com/support/SINGAPORE/Wireless%20Repeater/WL580E/User%20Manual/Aztech%20WL580E%20User%20Manual%20v1.3%20.pdf>


#### SIM卡接口设计

目前，我们手机的SIM卡主要分为2类：

* 一类是普通的SIM卡(15mm*25mm)
* 一类是最近几年流行起来的小卡(12m*15mm)
* 可能还有另外一类(9mm*12mm)的微型卡

因为，选用不同的SIM卡，我们就需要选用对应的SIM卡座。这是需要在设计前做出选择的。

ZTE模块推荐的SIM卡座是下面这款_CCM03-3011_：
<http://www.soselectronic.pl/a_info/resource/f/ccm03_nov11.pdf>


|Pin|Function||Pin|Name|
|---|---|---|---|---|
|C1|VCC||C5|GND|
|C2|RST||C6|VPP|
|C3|CLK||C7|IO|
|~~C4~~|||~~C8~~||


## 软件开发

由于目前Openwrt增加了对MT7688A技术支持。并且，现在MediaTek官方也在持续地对Openwrt提供技术支持。用户和MediaTek可以进行及时的技术互动。这些条件的存在，让我坚决的选择了Openwrt作为该项目的操作系统。

#### 开发环境的建立

对于这部分的内容，网络上有很多，我推荐的是在MediaTek在github上的官方代码。我在我的CSDN博客中也有一个简单的使用翻译博文<http://blog.csdn.net/hnhkj/article/details/50929777>。

#### 关键软件思考

后续更新......


## 参考信息

**MediaTek Labs** - <http://home.labs.mediatek.com/>  
**Huaiwei 4G模块** - <http://consumer.huawei.com/en/solutions/m2m-solutions/products/index.htm>  
**ZTE 4G模块** - <http://www.ztewelink.com/cn/products/module/>  
**PCI Express® Mini Card Electromechanical Specification**
<http://www.mod-book.ru/forum/attachment.php?attachmentid=1035>


