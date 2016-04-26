---
title: "一点一滴分析LinkIt™ Smart 7688 webUI"
author: "huang@irl-recording.com"
date: "2016年4月26日"
output: word_document
---

LinkIt 7688提供了一个友好的登录界面，源代码可以在下面的连接下载到：
https://github.com/MediaTek-Labs/linkit-smart-7688-webUI
翻译文档：
http://blog.csdn.net/hnhkj/article/details/50932118

通过对代码的初步分析：它采用了多种技术，例如：node.js, React组件，jQuery库等javascrip技术。牵扯的内容比较繁杂。如果说是我们希望对这个webUI有一个详细的了解得话，那么我们就要花费一定的时间来学习和搞清楚这些东西。对于一个javascript高手的话，那就另当别论了。对于我们新手的话，那就需要在繁杂的内容当中找到线索，来抽丝剥茧找到技术的核心。这样我们就可以让这个webUI为我所用了。这对于有些人来讲，是非常有用的。
接下来时间内，我会将我的分析心得一点一点记录下来。让有兴趣的朋友能够不走或少走弯路。

该webUI采用node.js编写，采用的是标准的commonJS规范，整个webUI包由多个相关的文件夹组成。编译后生长应用文件到build/目录下。严格来讲，生成的应用文件仍然是javascrip文件，只是对一些格式进行了缩减。我们完全可以通过对应用文件修改来实现功能修改。最便利的方法当然是对源代码进行修改，然后进行编译生成应用代码。webUI的目录结构参考如下：

linkit-smart-7688-webUI文档结构
---------------------------

```
linkit-smart-7688-webUI
  app
    build  //编译文件目录
      7688.png
      7688_duo.png
      en.app.js
      main.css
      riona-sans-light.otf
      riona-sans-medium.otf
      riona-sans-regular.otf
      zh-cn.app.js
      zh-tw.app.js
    css // css文件目录
      main.css
    font  // 字体文件目录
      riona-sans-light.otf
      riona-sans-medium.otf
      riona-sans-regular.otf
    img  // 图像文件目录
      7688.png
      7688.svg
      7688_duo.png
      7688duo.svg
      mediatek.png
    lib  // lib文件目录，核心文件保存在此处
      actions
        appActions.js
      components
        content.jsx
        header.jsx
        login.jsx
        network.jsx
        resetpassword.jsx
        sysinfo.jsx
      constants
        appConstants.js
      dispatchher
        appDispatcher.js
      stores
        appStore.js
      util
        rpcAPI.js
        ubusStatus.js
      app.jsx
    locale  // 本地化目录，首先了中英文显示的对照
      en.json
      zh-CN.json
      zh-TW.json
    index.html
    webpack.client.config.js
    zh-cn.html
    zh-tw.html
  docs
  rpc_demo_files  // 测试目录
  package.json
  webpack.config.js  
```
经过初步的分析，webUI的核心代码包含在lib文件夹下。所有的功能是实现都是由目录下面的这些代码来完成的。

linkit-smart-7688-webUI提供的开发环境
------------

对于webUI提供的开发环境，node和npm的安装对于新手来讲是一个挑战。我使用的是ubuntu 12版的，内置了node和npm。但是它们的版本都比较低，不是webUI要求的版本号。因而，整个模拟运行就不能进行下去。一连串的包版本不对应。利用apt-get install node， 这也是抓瞎。对于我的ubuntu来讲，我采用了指定版本的node来安装。至于，npm，我按照它的安装命令。这是我来回折腾了两天才搞定的，累死宝宝了0^0。
下面是我的ubuntu的安装过程：
```
$ wget https://nodejs.org/dist/v0.10.28/node-v0.10.28.tar.gz
$ tar -xvf node-v0.10.28.tar.gz
$ ./configure
$ make
$ sudo make install

$ sudo npm install npm@2.9.0 -g
```
如此操作，我就顺利安装上了指定版本的node和npm。good，一切就绪，可以开始我们的webUI调试之旅了。

```
$ git clone https://github.com/MediaTek-Labs/linkit-smart-webUI.git
$ npm i
$ npm run watch
```
一切并没有想象的那么顺利，又遇到问题卡壳了，显示下面的错误。一头雾水，没有心思看是怎么错误了，这么多的信息，哪里看起？

> node v0.10.28  npm v2.9.0 
> 
> ubuntu@ubuntu-virtual-machine:~/openwrt/linkit-smart-webUI$ sudo npm
> run watch 
> 
> \> linkit-smart-7688-webui@0.0.1 watch /home/ubuntu/openwrt/linkit-smart-webUI 
> \> NODE_ENV=dev webpack-dev-server --port 8081 --colors --inline --hot --config ./webpack.config.js 
> 
> Start building: dev 
> 
> module.js:340  throw err;  ^  Error: Cannot find module
> './locale/zh-cn'  at Function.Module._resolveFilename
> (module.js:338:15)  at Function.Module._load (module.js:280:25)  at
> Module.require (module.js:364:17)  at require (module.js:380:17)  at
> Object.<anonymous>
> (/home/ubuntu/openwrt/linkit-smart-webUI/app/webpack.client.config.js:9:12)
> at Module._compile (module.js:456:26)  at normalLoader
> (/home/ubuntu/openwrt/linkit-smart-webUI/node_modules/babel-core/lib/api/register/node.js:199:5)
> at Object.require.extensions.(anonymous function) [as .js]
> (/home/ubuntu/openwrt/linkit-smart-webUI/node_modules/babel-core/lib/api/register/node.js:216:7)
> at Module.load (module.js:356:32)  at Function.Module._load
> (module.js:312:12)  at Module.require (module.js:364:17)  at require
> (module.js:380:17) 
> 
> npm ERR! Linux 3.2.0-95-generic-pae  npm ERR! argv "node"
> "/usr/local/bin/npm" "run" "watch"  npm ERR! node v0.10.28  npm ERR!
> npm v2.9.0  npm ERR! code ELIFECYCLE  npm ERR!
> linkit-smart-7688-webui@0.0.1 watch: `NODE_ENV=dev webpack-dev-server
> --port 8081 --colors --inline --hot --config ./webpack.config.js`  npm ERR! Exit status 8  npm ERR!  npm ERR! Failed at the
> linkit-smart-7688-webui@0.0.1 watch script 'NODE_ENV=dev
> webpack-dev-server --port 8081 --colors --inline --hot --config
> ./webpack.config.js'.  npm ERR! This is most likely a problem with the
> linkit-smart-7688-webui package,  npm ERR! not with npm itself.  npm
> ERR! Tell the author that this fails on your system:  npm ERR!
> NODE_ENV=dev webpack-dev-server --port 8081 --colors --inline --hot
> --config ./webpack.config.js  npm ERR! You can get their info via:  npm ERR! npm owner ls linkit-smart-7688-webui  npm ERR! There is
> likely additional logging output above. 
> 
> npm ERR! Please include the following file with any support request: 
> npm ERR! /home/ubuntu/openwrt/linkit-smart-webUI/npm->debug.log

没有办法，硬着头皮也要上。看吧！万事只要静下心来，就都可以解决。发现了问题的所在。原来是源码的问题，原来是app/webpack.client.config.js引用的./locale/zh-cn 和./locale/zh-tw。但是，在实际的目录下的文件名称是这样子的zh-CN.json和zh-TW.json，大小写不同。找不到指定的文件因而出现了这个问题。果断修改app/webpack.client.config.js，将对应的小写字母改称对应的大写字母。重新运行npm run watch。good，没有错误信息的。
```
ubuntu@ubuntu-virtual-machine:~/openwrt/hnhkj/linkit-smart-7688-webUI$ npm run watch

> linkit-smart-7688-webui@0.0.1 watch /home/ubuntu/openwrt/hnhkj/linkit-smart-7688-webUI
> NODE_ENV=dev webpack-dev-server --port 8081 --colors --inline --hot --config ./webpack.config.js

Start building:  dev
http://localhost:8081/
webpack result is served from http://127.0.0.1:8081/build/
content is served from /home/ubuntu/openwrt/hnhkj/linkit-smart-7688-webUI

```
这条命令还没有实现，因为我的ubuntu没有安装chrome。在浏览器中键入 http://127.0.0.1:8081/app.  ok，显示登录界面了。
```
$ open -n -a /Applications/Google\ Chrome.app --args --user-data-dir="/tmp/chrome_dev_session" --disable-web-security
```

还没有完，界面只是登录界面，对登录界面的修改可以得到验证。但是对登录后的界面如何验证，还需要以后再研究！

到目前为止，对app的源代码问题应该不大了，验证也可以慢慢研究了。可是如何将进行修改后的源码编译到build/目录下面哪？这是一个新的问题了。我原来以为readme中的开发流程会自动将源码编译到build中，经过测试并没有实现。经过一番研究，我们需要采用新的方法。

javascrip源码打包
-------------
javascrip源码需要经过编译后，生成简化的javascrip代码到build/下面。这种方法大大减小了访问时的数据量。
该webUI采用了webpack工具，Webpack 是一个前端资源加载/打包工具。参考连接https://hulufei.gitbooks.io/react-tutorial/content/webpack.html。经过webpack打包后，jiavascrip源代码被打包到build/目录下。
```
$ sudo npm install -g webpack
$ sudo npm install -g babel-core babel-preset-es2015 babel-preset-react
$ sudo npm install babel-loader coffee-loader
$ npm run watch
```
**运行webpack自动对源代码进行打包。**

```
ubuntu@ubuntu-virtual-machine:~/openwrt/hnhkj/linkit-smart-7688-webUI$    npm run watch
   
   > linkit-smart-7688-webui@0.0.1 watch /home/ubuntu/openwrt/hnhkj/linkit-smart-7688-webUI
   > NODE_ENV=dev webpack-dev-server --port 8081 --colors --inline --hot --config ./webpack.config.js
       Start building:  dev http://localhost:8081/ webpack result is served    from http://127.0.0.1:8081/build/ content is served from    /home/ubuntu/openwrt/hnhkj/linkit-smart-7688-webUI
```

Openwrt和LinkIt webUI接口
----------------------

Openwrt提供了新的借口LUCI2，该接口提供ubus技术。这种技术可以使用html+css+js和openwrt进行沟通。

又过了几天的学习，我对LinkIt Smart 7688 webUI有了新的认识。原来，该webUI采用的是openwrt的ubus技术，通过uhttpd-mod-ubus插件进行的服务控制。该方法是通过json数据包实现的对openwrt系统的数据读取。
在rpc_demo_files目录下面有一个测试文件，该测试文件很好地说明了各个功能的实现测试。原来我是多么的无知！

![login界面修改](img/image001.jpg)
分析总结
----
对于该webUI的设计，主要存在的技术手段：
1. web技术 html+css+javascript
2. ubus

ubus是核心，做为openwrt服务器对外接口。web技术为前端技术，实现显示介面和控制提交。至于build中的文件，使一种数据的压缩。它是将css, javascript, 图片等信息压缩到了这个目录下面，从而减少了通讯的数据量，提高相应的速度。

对于openwrt的相关技术，后续还会继续分析！至于这个webUI，也会继续分析。分析的结果会持续更新！

如果有志同道合之人，也可分享您的心得。我们共同讨论学习，共同进步。浅显认识，大虾别见笑！ 0^0


技术参考：
-----
ubus (OpenWrt micro bus architecture)  
https://wiki.openwrt.org/doc/techref/ubus?s[]=ubus  
node.js官方网站  
https://nodejs.org  
commonJS规范  
https://webpack.github.io/docs/commonjs.html  
React库中文说明  
http://reactjs.cn/  
jQuery 教程  
http://www.w3school.com.cn/jquery/index.asp  
javascrip教程  
http://www.w3school.com.cn/b.asp  
JSON教程  
http://www.w3school.com.cn/json/index.asp  
XML教程  
http://www.w3school.com.cn/x.asp  

如果英文好点可以访问http://www.w3schools.com/网站  
