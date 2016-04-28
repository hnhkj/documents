---
title: "doxygen应用"
author: "hnhkj@163.com"
date: "2016年4月24日"
output: html_document
---


## 工具下载及安装

* Doxygen可以从一套源文件开始，生成HTML格式的在线类浏览器。笔者采用的版本是 Doxygen1.8.9.1

* Microsoft HTML Help Workshop是微软开发，用于本工程创建*.chm文件，笔者上官网下载最新的 htmlhelp

* Graphviz用于配合doxygen使用，提取函数之间、头文件之间的调用关系，笔者使用的版本是 graphviz-2.38 .

## doxygen

## 翻译

## Documenting the code//记录代码

#### Special comment blocks//特定的注释块

#### Comment blocks for C-like languages (C/C++/C#/Objective-C/PHP/Java)

* 1. JavaDoc类型

```
/**  
 * ... text ...  
 */  

```

* 2. Qt类型
 

#### 注释


#### file

#### author

#### version

#### date

#### brief //简单描述

对于\brief命令，有几个


```
/*! \brief Brief description.  
 *         Brief description continued.  
 *
 *  Detailed description starts here.  
 */  
```

## Special Commands 

* \a
* \addindex
* \addtogroup
* \anchor
* \arg
* \attention
* \author
* \authors
* \b
* \brief
* \bug
* \c
* \callergraph
* \callgraph
* \category
* \cite
* \class
* \code
* \cond
* \copybrief
* \copydetails
* \copydoc
* \copyright
* \date
* \def
* \defgroup
* \deprecated
* \details
* \diafile
* \dir
* \docbookonly
* \dontinclude
* \dot
* \dotfile
* \e
* \else
* \elseif
* \em
* \endcode
* \endcond
* \enddocbookonly
* \enddot
* \endhtmlonly
* \endif
* \endinternal
* \endlatexonly
* \endlink
* \endmanonly
* \endmsc
* \endparblock
* \endrtfonly
* \endsecreflist
* \endverbatim
* \enduml
* \endxmlonly
* \enum
* \example
* \exception
* \extends
* \f$
* \f[
* \f]
* \f{
* \f}
* \file
* \fn
* \headerfile
* \hidecallergraph
* \hidecallgraph
* \hideinitializer
* \htmlinclude
* \htmlonly
* \idlexcept 
* \if
* \ifnot
* \image
* \implements
* \include
* \includelineno
* \ingroup
* \internal
* \invariant
* \interface
* \latexinclude
* \latexonly
* \li
* \line
* \link
* \mainpage
* \manonly
* \memberof
* \msc
* \mscfile
* \n
* \name
* \namespace
* \nosubgrouping
* \note
* \overload
* \p
* \package
* \page
* \par
* \paragraph
* \param
* \parblock
* \post
* \pre
* \private
* \privatesection
* \property
* \protected
* \protectedsection
* \protocol
* \public
* \publicsection
* \pure
* \ref
* \refitem
* \related
* \relates
* \relatedalso
* \relatesalso
* \remark
* \remarks
* \result
* \return
* \returns
* \retval
* \rtfonly
* \sa
* \secreflist
* \section
* \see
* \short
* \showinitializer
* \since
* \skip
* \skipline
* \snippet
* \startuml
* \struct
* \subpage
* \subsection
* \subsubsection
* \tableofcontents
* \test
* \throw
* \throws
* \todo
* \tparam
* \typedef
* \union
* \until
* \var
* \verbatim
* \verbinclude
* \version
* \vhdlflow
* \warning
* \weakgroup
* \xmlonly
* \xrefitem
* \$
* \@
* \\
* \&
* \~
* \<
* \>
* \#
* \%
* \"
* \.
* \::
* \|
* \&ndash;
* \&mdash;

#### \attention { attention text } 注意文本

Starts a paragraph where a message that needs attention may be entered. The paragraph will be indented. The text of the paragraph has no special internal structure. All visual enhancement commands may be used inside the paragraph. Multiple adjacent \attention commands will be joined into a single paragraph. The \attention command ends when a blank line or some other sectioning command is encountered.

#### \exception <exception-object> {exception description} 对一个异常对象进行注释。

#### \warning { warning message } 警告消息（一些需要注意的事情）

Starts a paragraph where one or more warning messages may be entered. The paragraph will be indented. The text of the paragraph has no special internal structure. All visual enhancement commands may be used inside the paragraph. Multiple adjacent \warning commands will be joined into a single paragraph. Each warning description will start on a new line. Alternatively, one \warning command may mention several warnings. The \warning command ends when a blank line or some other sectioning command is encountered. See section \author for an example.

#### \todo { things to be done } 对将要做的事情进行注释

#### \see {comment with reference to other items } 一段包含其他部分引用的注释，中间包含对其他代码项的名称，自动产生对其的引用链接。


#### \relates <name> 通常用做把非成员函数的注释文档包含在类的说明文档中。

#### \since {text} 通常用来说明从什么版本、时间写此部分代码。

#### \deprecated

#### \pre { description of the precondition } 用来说明代码项的前提条件。

#### \post { description of the postcondition } 用来说明代码项之后的使用条件。

#### \code 在注释中开始说明一段代码，直到@endcode命令。

#### \@endcode 注释中代码段的结束。

## 参考文档

<http://www.tuicool.com/articles/imqi6ry>

<http://www.360doc.com/content/12/0812/14/7851074_229747305.shtml>