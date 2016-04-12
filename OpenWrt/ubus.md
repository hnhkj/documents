https://wiki.openwrt.org/doc/techref/ubus

#ubus (OpenWrt micro bus architecture)//ubus (OpenWrt micro bus 架构)

To provide communication between various daemons and applications in OpenWrt an ubus project has been developed. It consists of few parts including daemon, library and some extra helpers.

为了在OpenWrt中提供守护进程和应用程序间的通讯，开发了ubus项目工程。它包含了守护进程、库以及一些额外的帮助程序

The heart of this project is ubusd daemon. It provides interface for other daemons to register themselves as well as sending messages. For those curious, this interface is implemented using Unix socket and it uses TLV (type-length-value) messages.

核心部分是ubusd守护进程，它提供了其他守护进程将自己注册以及发送消息的接口。因为这个，接口通过使用Unix socket来实现，并使用TLV(type-length-value)消息

To simplify development of software using ubus (connecting to it) a library called libubus has been created.

为了简化软件的开发，可以使用已有的libubus库来使用ubus(连接ubus)。

Every daemon registers set of own paths under specific namespace. Every path can provide multiple procedures with various amount of arguments. Procedures can reply with a message.

每个守护进程在自己的名称空间中注册自有的路径。每个路径可以提供多个带有不定数量参数的方法，方法可以通过消息回复调用。

The code is published under LGPL 2.1 and can be found via git at http://git.openwrt.org/project/ubus.git. It's included in OpenWrt since r28499.

代码在LGPL 2.1授权方法下发布，你可以通过git在git://nbd.name/luci2/ubus.git或通过http在http://nbd.name/gitweb.cgi?p=luci2/ubus.git;a=summary获取。 ubus从r28499起被包含在OpenWrt中。

##Command-line ubus tool  //ubus命令行工具

The ubus command line tool allows to interact with the ubusd server (with all currently registered services). It's useful for investigating/debugging registered namespaces as well as writing shell scripts. For calling procedures with parameters and returning responses it uses user-friendly JSON format. Below is an explanation of its commands.

ubus可以和ubusd服务器交互(和当前所有已经注册的服务). 它对研究和调试注册的命名空间以及编写脚本非常有用。对于调用带参数和返回信息的方法，它使用友好的JSON格式。下面是它的命令说明。

##list  //列表

By default, list all namespaces registered with the RPC server:

缺省列出所有通过RPC服务器注册的命名空间:

    root@uplink:~# ubus list
    network
    network.device
    network.interface.lan
    network.interface.loopback
    network.interface.wan
    root@uplink:~#`

If invoked with -v, additionally the procedures and their argument signatures are dumped in addition to the namespace path:

如果调用时包含参数-v,将会显示指定命名空间更多方法参数等信息:

    root@uplink:~# ubus -v list network.interface.lan
    'network.interface.lan' @099f0c8b
	"up": {  }
	"down": {  }
	"status": {  }
	"prepare": {  }
	"add_device": { "name": "String" }
	"remove_device": { "name": "String" }
	"notify_proto": {  }
	"remove": {  }
	"set_data": {  }
    root@uplink:~#

##call //调用

Calls a given procedure within a given namespace and passes given message to it:

调用指定命名空间中指定的方法，并且通过消息传递给它:

    root@uplink:~# ubus call network.interface.wan status
    {
    	"up": true,
    	"pending": false,
    	"available": true,
    	"autostart": true,
    	"uptime": 86017,
    	"l3_device": "eth1",
    	"device": "eth1",
    	"address": [
    		{
    			"address": "178.25.65.236",
    			"mask": 21
    		}
	    ],
    	"route": [
    		{
    			"target": "0.0.0.0",
    			"mask": 0,
    			"nexthop": "178.25.71.254"
    		}
    	],
    	"data": {
		
	    }
    }
    root@uplink:~#

The message argument must be a valid JSON string, with keys and values set according to the function signature:

消息参数必须是有效的JSON字符串，并且携带函数所要求的键及值:

	root@uplink:~# ubus call network.device status '{ "name": "eth0" }'
	{
		"type": "Network device",
		"up": true,
		"link": true,
		"mtu": 1500,
		"macaddr": "c6:3d:c7:90:aa:da",
		"txqueuelen": 1000,
		"statistics": {
			"collisions": 0,
			"rx_frame_errors": 0,
			"tx_compressed": 0,
			"multicast": 0,
			"rx_length_errors": 0,
			"tx_dropped": 0,
			"rx_bytes": 0,
			"rx_missed_errors": 0,
			"tx_errors": 0,
			"rx_compressed": 0,
			"rx_over_errors": 0,
			"tx_fifo_errors": 0,
			"rx_crc_errors": 0,
			"rx_packets": 0,
			"tx_heartbeat_errors": 0,
			"rx_dropped": 0,
			"tx_aborted_errors": 0,
			"tx_packets": 184546,
			"rx_errors": 0,
			"tx_bytes": 17409452,
			"tx_window_errors": 0,
			"rx_fifo_errors": 0,
			"tx_carrier_errors": 0
		}
	}
	root@uplink:~#

##listen  //侦听

Setup a listening socket and observe incoming events:

设置一个监听socket并观察进入的事件:

	root@uplink:~# ubus listen &
	root@uplink:~# ubus call network.interface.wan down
	{ "network.interface": { "action": "ifdown", "interface": "wan" } }
	root@uplink:~# ubus call network.interface.wan up
	{ "network.interface": { "action": "ifup", "interface": "wan" } }
	{ "network.interface": { "action": "ifdown", "interface": "he" } }
	{ "network.interface": { "action": "ifdown", "interface": "v6" } }
	{ "network.interface": { "action": "ifup", "interface": "he" } }
	{ "network.interface": { "action": "ifup", "interface": "v6" } }
	root@uplink:~# 

##send  //发送

Send an event notification:

发送一个事件提醒:

	root@uplink:~# ubus listen &
	root@uplink:~# ubus send foo '{ "bar": "baz" }'
	{ "foo": { "bar": "baz" } }
	root@uplink:~# 


##Access to ubus over HTTP //通过HTTP访问ubus

There is an uhttpd plugin called uhttpd-mod-ubus that allows ubus calls using HTTP protocol. Requests have to be send to the /ubus URL (unless changed) using POST method. This interface uses jsonrpc v2.0 There are a few steps that you will need to understand. (Documentation written while using BarrierBreaker r40831, ymmv)

有一个uhttpd的插件uhttpd-mod-ubus，它可允许通过HTTP协议调用ubus。请求必须使用POST方法发送到/ubs地址（除非改变）。这个接口使用jsonrpc v2.0，有几个步骤需要理解。（写文档的时候使用BarrierBreaker r40831,ymmv）。

###ACLs(access control list) //访问控制列表

While logged into via ssh, you have direct, full access to ubus. When you're accessing the /ubus url in uhttpd however, uhttpd runs "ubus call session access '{ ubus-rpc-session, requested-object, requested-method }' and whoever is providing the ubus session.* namespace is in charge of implementing the ACL. This happens to be rpcd at the moment, with the http-json interface, for friendly operation with browser code, but this is just one possible implmementation. Because we're using rpcd to implement the ACLs at this time, this allows/requires (depending on your point of view) ACLs to be configured in /usr/share/rpcd/acl.d/*.json. The names of the files in /usr/share/rpcd/acl.d/*.json don't matter, but the top level keys define roles. The default acl, listed below, only defines the login methods, so you can login, but you still wouldn't be able to do anything.

当通过ssh登录后，你可以直接能完全访问ubus。 When you're accessing the /ubus url in uhttpd however, uhttpd runs "ubus call session access '{ ubus-rpc-session, requested-object, requested-method }' and whoever is providing the ubus session.* namespace is in charge of implementing the ACL. This happens to be rpcd at the moment, with the http-json interface, for friendly operation with browser code, but this is just one possible implmementation. 因Because we're using rpcd to implement the ACLs at this time, this allows/requires (depending on your point of view) ACLs to be configured in /usr/share/rpcd/acl.d/*.json. The names of the files in /usr/share/rpcd/acl.d/*.json don't matter, but the top level keys define roles. The default acl, listed below, only defines the login methods, so you can login, but you still wouldn't be able to do anything.默认的ACL，listed below, 仅仅定义登入方法。如此，你能登入，但是你不能做任何事情。

 但是，当你在uhttpd内访问/ubus地址时，uhttpd运行"ubus call session"访问 '{ ubus-rpc-session, requested-object, requested-method }' 和无论是谁正在提供的ubus session。？？*namespace负责执行ACL。？？This happens to be rpcd at the moment, with the http-json interface, for friendly operation with browser code, but this is just one possible implmementation.



	{
        "unauthenticated": {
                "description": "Access controls for unauthenticated requests",
                "read": {
                        "ubus": {
                                "session": [ "access", "login" ]
                        }
                }
        }
	}

An example of a complicated ACL, allowing quite fine grained access to different ubus modules and methods is available in the Luci2 project

An example of a "security is for suckers" config, where a "superuser" ACL group is defined, allowing unrestricted access to everything, is shown below. (This illustrates the usage of '*' definitions in the ACLs, but keep reading for better examples) Placing this file in /usr/share/rpcd/acl.d/superuser.json will help you move forward to the next steps.

	{
        "superuser": {
                "description": "Super user access role",
                "read": {
                        "ubus": {
                                "*": [ "*" ]
                        },
                        "uci": [ "*" ]
                },
                "write": {
                        "ubus": {
                                "*": [ "*" ]
                        },
                        "uci": [ "*" ]
                }
        }
	}

Below is an example of an ACL definition that only allows access to some specific ubus modules, rather than unrestricted 
access to everything.

下面是一个ACL定义，只允许访问一些特定的ubus模组，而不是无限制的访问任何事情。


	{
        "lesssuperuser": {
                "description": "not quite as super user",
                "read": {
                        "ubus": {
                                "file": [ "*" ],
                                "log": [ "*" ],
                                "service": [ "*" ],
                        },
                },
                "write": {
                        "ubus": {
                                "file": [ "*" ],
                                "log": [ "*" ],
                                "service": [ "*" ],
                        },
                }
        }
	}

Note: Before we leave this section, you may have noticed that there's both a "ubus" and a "uci" section, even though ubus has a uci method. The uci: scope is used for the uci api provided by rpcd to allow defining per-file permissions because using the ubus scope you can only say "uci set" is allowed or not allowed but not specify that it is allowed to e.g. modify /e/c/system but not /e/c/network If your application/ACL doesn't need UCI access, you can just leave out the UCI section altogether.

注意：我们离开这部分之前，你也许注意到“ubus”和“uci”两部分，即使ubus有一个uci方法。


###Authentication  //认证

Now that we have an ACL that allows operations beyond just logging in, we can actually try this out. As mentioned, rpcd is handling this, so you need an entry in /etc/config/rpcd

现在，我们有一个ACL了，它允许登录之外的操作。 如提到的，rpcd处理这个，所以你需要一个在/etc/config/rpcd中的入口。

	config login
		option username 'root'
		option password '$p$root'
		list read '*'
		list write '*'

The $p magic means to look in /etc/shadow and the $root part means to use the password for the root user in that file. The list of read and write sections, those map acl roles to user accounts. You can also use $1$<hash>which is a "crypt()" hash, using SHA1, exactly as used in /etc/shadow. You can generate these with, eg, "uhhtpd -m secret"

$p的意思查询 /etc/shadow，$roo

To login and receive a session id:

登录并接收会话ID：


	$ curl -d '{ "jsonrpc": "2.0", "id": 1, "method": "call", "params": [ "00000000000000000000000000000000", "session", "login", { "username": "root", "password": "secret"  } ] }'  http://your.server.ip/ubus

	{"jsonrpc":"2.0","id":1,"result":[0,{"ubus_rpc_session":"c1ed6c7b025d0caca723a816fa61b668","timeout":300,"expires":299,"acls":{"access-group":{"superuser":["read","write"],"unauthenticated":["read"]},"ubus":{"*":["*"],"session":["access","login"]},"uci":{"*":["read","write"]}},"data":{"username":"root"}}]}

The sessionid "00000000000000000000000000000000" (32 zeros) is a special null-session which just has enough access rights for the session.login ubus call. A session has a timeout, that is specified when you login, but has a default. You can request a longer timeout in your initial login call, with a "timeout" key in the login parameters section.

If you ever receive a response like, {"jsonrpc":"2.0","id":1,"result":[6]} That is a valid jsonrpc response, 6 is the ubus code for UBUS_STATUS_PERMISSION_DENIED (you'll get this if you try and login before setting up the "superuser" file, or any file that gives you anymore rights than just being allowed to attempt logins.

To list all active sessions, try ubus call session list

###Session management//会话管理

A session is automatically renewned on every use. There are plans to use these sessions even for luci1, but at present, if you use this interface in a luci1 environment, you'll need to manage sessions yourself.

###Actually making calls

Now that you have a ubus_rpc_session you can make calls, based on your ACLs and the available ubus services.  ubus list -v is your primary documentation on what can be done, but see the rest of this page for more information. For example, ubus list file -v returns

	'file' @24a6bd4a
		"read":{"path":"String","data":"String"}
		"write":{"path":"String","data":"String"}
		"list":{"path":"String","data":"String"}
		"stat":{"path":"String","data":"String"}
		"exec":{"command":"String","params":"Array","env":"Table"}

The json container format is:

json容器格式：

	{ "jsonrpc": "2.0",
	  "id": <unique-id-to-identify-request>, 
	  "method": "call",
	  "params": [
    	         <ubus_rpc_session>, <ubus_object>, <ubus_method>, 
    	         { <ubus_arguments> }
    	        ]
	}

The "id" key is merely echo'ed by the server, so it needs not be strictly unique, it's mainly intended for client software to easily correlate responses to previously made requests. It's type is either a string or a number, so it can be an sha1 hash, md5 sum, sequence counter, unix timestamp, ….

An example request to read a file would be:

请求读一个文件：

	$ curl -d '{ "jsonrpc": "2.0", "id": 1, "method": "call", "params": [ "7cba69a942c0e9db1eb7982cd91f3a48", "file", "read", { "path": "/tmp/hello.karl" } ] }'  http://eg-134867.local/ubus
	{"jsonrpc":"2.0","id":1,"result":[0,{"data":"this is the contents of a file\n"}]}

###Lua module for ubus//关于ubus的lua模组

This is even possible to use ubus in lua scripts. Of course it's not possible to use native libraries directly in lua, so an extra module has been created. It's simply called ubus and is a simple interface between lua scripts and the ubus (it uses libubus internally).

Load module

载入模组

	require "ubus"

###Establish connection //建立连接

	local conn = ubus.connect()
	if not conn then
	    error("Failed to connect to ubusd")
	end

Optional arguments to connect() are a path to use for sockets (pass nil to use the default) and a per call timeout value (in milliseconds)

	local conn = ubus.connect(nil, 500) -- default socket path, 500ms per call timeout

###Iterate all namespaces and procedures  //循环访问所有的命名空间和程序

	local namespaces = conn:objects()
	for i, n in ipairs(namespaces) do
    	print("namespace=" .. n)
	    local signatures = conn:signatures(n)
	    for p, s in pairs(signatures) do
	        print("\tprocedure=" .. p)
	        for k, v in pairs(s) do
	            print("\t\tattribute=" .. k .. " type=" .. v)
	        end
	    end
	end

###Call a procedure //调用一个程序

	local status = conn:call("network.device", "status", { name = "eth0" })
	for k, v in pairs(status) do
	    print("key=" .. k .. " value=" .. tostring(v))
	end

###Close connection  //关闭连接

	conn:close()

###Namespaces & Procedures

As explained earlier, there can be many different daemons (services) registered in ubus. Below you will find a list of the most common projects with namespaces, paths and procedures they provide.

###netifd

DESIGN document at repo of netifd

###rpcd

Project rpcd is set of small plugins providing sets of ubus procedures in separated namespaces. These plugins are not strictly related to any particular software (like netifd or dhcp) so it wasn't worth it to implement them as separated projects.


###Example code snippets//代码片断

Check if Link is up using devstatus and Json

	#!/bin/sh
	
	. /usr/share/libubox/jshn.sh
	
	WANDEV="$(uci get network.wan.ifname)"
	
	json_load "$(devstatus $WANDEV)"
	
	json_get_var var1 speed
	json_get_var var2 link
	
	echo "Speed: $var1"
	echo "Link: $var2"
