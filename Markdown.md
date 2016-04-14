---
title: "Markdown应用"
author: "hnhkj@163.com"
date: "2016年4月12日"
output: html_document
---

## 前言

我查找了几款离线的编辑器：
ATOM，Markdown+R,MarkdownPad2

## Markdown语法



## 流行的编辑器

#### Pandoc

Pandoc User's Guide <http://pandoc.org/README.html>

参考文档：

<http://www.ituring.com.cn/article/746>


Markdown写作进阶：Pandoc入门浅谈<http://www.yangzhiping.com/tech/pandoc.html>


  Right     Left     Center     Default
-------     ------ ----------   -------
     12     12        12            12
    123     123       123          123
      1     1          1             1

Table:  Demonstration of simple table syntax.

多行表格
-------------------------------------------------------------
 Centered   Default           Right Left
  Header    Aligned         Aligned Aligned
----------- ------- --------------- -------------------------
   First    row                12.0 Example of a row that
                                    spans multiple lines.

  Second    row                 5.0 Here's another one. Note
                                    the blank line between
                                    rows.
-------------------------------------------------------------

Table: Here's the caption. It, too, may span

#### R Markdown

R markdown是R语言运行环境__RStudio__所使用的扩展的markdown标签语言，能够方便的利用R语言生成web格式的报告。它包括核心的Markdown语法，并能将其中插入的R代码区块的运行结果显示在最终文档里。

详细的文档可以参考<http://rmarkdown.rstudio.com/>，中文的话可以参考<http://www.jianshu.com/p/gwTSKt>。

对于RStudio软件来讲，确实是一个非常强大的工具软件。它可以将R markdown文件轻而易举地转换成html,docx,pdf文件。而且转换的结果非常的漂亮。这是我最为喜欢的一款软件。

**该软件还有一个强大的功能，能够将markdown中引用的图片，转换后加载到html，产生一个单一的html文件。这样减少了对其它文件的依赖。**

##### 问题集

* 不能转换为PDF文件
	<http://blog.rainy.im/2015/05/16/rmarkdown-in-rstudio/>


#### Atom
Atom是Github开发的一款软件，该软件演习了sublime的一些方法。是用起来也不错。<https://www.aswifter.com/2015/07/26/atom-markdown-editor/>

这个软件的优点是：

1. 可以实时显示御览结果  
2. 支持表格功能

不足：

1. 不能将图片压缩到html文件中。  

#### sublime
优点：
* 可以将图片压缩到html中。

缺点：
* 不能进行实时御览。

#### MarkdownPad2
是一款很不错的软件，从我查询到的结果来讲，这是windows下最为流行的软件。但是可惜的是，它是一款收费软件。免费版本只是实现了一些基本Markdown语法，对于表格不支持。所以，我只是用它来进行一些基本Markdown编辑。


## 总结


## 参考文档

Markdown 代码高亮 <http://heckaitor.github.io/2014/04/10/hexo-markdown-code-highlight/>  
Getting started with Markdown <http://publish.illinois.edu/commonsknowledge/2014/01/23/getting-started-with-markdown/>
