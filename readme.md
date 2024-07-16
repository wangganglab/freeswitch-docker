# xswitch

> 注意：基于杜老板的小樱桃的镜像

很多朋友想试用FreeSWITCH，但是从源代码安装比较复杂。FreeSWITCH虽然有相应的安装包，但用起来也不那么方便。

现在，Docker已经成了事实上的部署方式，为了大家更容易使用，我们做了这一镜像，希望对大家有用。

# 环境准备

首先，你要有一个Docker环境，如何安装Docker超出了本文的范围，您可以参阅以下链接，或自行查找相关资料安装。安装时注意有选择国内镜像站点的一些设置比较有用，在以后使用的时候可以节省一些下载镜像的时间。

* https://www.runoob.com/docker/windows-docker-install.html
* https://www.runoob.com/docker/ubuntu-docker-install.html
* https://www.runoob.com/docker/macos-docker-install.html
* https://yq.aliyun.com/articles/625403

Docker Compose也需要安装，但不是必须的，只是安装了能更方便些，下面的命令大都依赖于Docker Compose。

本镜像支持在Linux、Mac、Windows宿主机上运行。

# 环境变量

以下环境变量，有相关的默认值

* `FS_INTERNAL_SIP_PORT`：默认SIP端口
* `SIP_TLS_PORT`：SIP TLS端口
* `SIP_PUBLIC_PORT` SIP `public` Profile端口
* `SIP_PUBLIC_TLS_PORT`：SIP `public` Profile TLS端口
* `RTP_START`：起始RTP端口
* `RTP_END`：结束RTP端口
* `EXT_IP`：宿主机IP，或公网IP，默认SIP Profile中的`ext-sip-ip`及`ext-rtp-ip`会用到它。
* `FREESWITCH_DOMAIN`：默认的FreeSWITCH域
* `LOCAL_NETWORK_ACL`：默认为`none`，在`host`网络模式下可以关闭。

# 常用命令

常用命令都在Makefile中，看起来也很直观。如果你的环境中没有`make`，也可以直接运行相关的命令。

* `make setup`：初始化环境，如果`.env`不存在，会从`env.example`复制。
* `make start`：启动镜像。
* `make run`：启动镜像并进入后台模式。
* `make cli`：进入容器并进入`fs_cli`。
* `make bash`：进入容器并进入`bash` Shell环境。可以进一步执行`fs_cli`等。
* `make stop`：停止容器。
* `make pull`：更新镜像，更新后可以用。

如果没有安装Docker Compose，也可以直接使用Docker命令启动容器，如：

```bash
docker run -it --network host --name freeswitch -v /opt/freeswitch/log:/usr/local/freeswitch/log /etc/localtime:/etc/localtime:ro /opt/freeswitch/conf:/usr/local/freeswitch/conf -d freeswitch-1.10.7
```

可以看出，这样需要输入很多参数，所以，还是使用Docker Compose比较方便。

# 修改配置

可以直接进入容器修改配置，并在终端上`reload xml`或重载相关模块使之生效。但在容器重启后修改会丢失。

如果想保持自己的修改，那就需要把配置文件放到宿主机上。通过以下命令可以生成默认的配置文件。

`make eject`

然后修改`docker-compose.yml`，取消掉以下行的注释：

```yaml
    volumes:
      - ./conf/:/usr/local/freeswitch/conf:cached
```

修改后需要重启镜像：

```bash
make stop
make start
```


# `host`模式网络

典型的Docker容器运行方式是NAT型的网络，有时候，使用`host`模式网络会比较方便（因为少了一层NAT）。本镜像不需要特殊的配置就可以使用`host`网络，只需要在`docker-compose.yml`中启用即可。

如果环境变量中没有`EXT_IP`，则可能无法启动Sofia Profile，请禁掉`default.xml`和`public.xml`中的`ext-sip-ip`和`ext-rtp-ip`参数。

默认的配置是NAT模式，我们在Profile中启动了如下配置：

```xml
    <param name="local-network-acl" value="$${local_network_acl}"/>
```

注意，该环境变量默认为`none`，它实际上是一个不存在的ACL，所以FreeSWITCH对任何来源IP都会认为它在NAT后面。

如果在`host`网络模式下可以在`.env`中注释掉这个环境变量，让它使用默认的`localnet.auto`。
