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

#### \warning { warning message } 警告消息

Starts a paragraph where one or more warning messages may be entered. The paragraph will be indented. The text of the paragraph has no special internal structure. All visual enhancement commands may be used inside the paragraph. Multiple adjacent \warning commands will be joined into a single paragraph. Each warning description will start on a new line. Alternatively, one \warning command may mention several warnings. The \warning command ends when a blank line or some other sectioning command is encountered. See section \author for an example.



## 参考文档

<http://www.tuicool.com/articles/imqi6ry>

<http://www.360doc.com/content/12/0812/14/7851074_229747305.shtml>