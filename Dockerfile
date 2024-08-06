FROM debian:bookworm

ARG VERSION
ARG TOKEN

# 安装依赖环境
RUN sed -i s@/deb.debian.org/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt-get clean && apt-get update && \
    apt-get install -yq gnupg2 wget ca-certificates lsb-release vim sngrep && \
    wget --http-user=signalwire --http-password=$TOKEN -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg && \
    echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" > /etc/apt/auth.conf && \
    echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list && \
    echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list && \
    apt-get update -y && apt-get build-dep freeswitch -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 下载FreeSwitch
RUN cd /opt/ && \
    wget -c https://files.freeswitch.org/releases/freeswitch/freeswitch-${VERSION}.-release.tar.gz && \
    tar -C /opt/ -xzvf freeswitch-${VERSION}.-release.tar.gz && \
    rm freeswitch-${VERSION}.-release.tar.gz

# 安装模块
COPY ./build/modules.conf /opt/freeswitch-${VERSION}.-release/modules.conf
# RUN cd /opt/freeswitch-${VERSION}.-release && ./configure && make -j4 && make all install &&  make cd-sounds-install cd-moh-install && rm -rf /opt/freeswitch-${VERSION}.-release
RUN cd /opt/freeswitch-${VERSION}.-release && ./configure && make -j4 && make all install 

# 添加LuaJIT并安装
ADD ./build/LuaJIT-2.0.5.tar.gz /opt/
RUN cd /opt/LuaJIT-2.0.5/ && make -j4 && make install && rm -rf /opt/LuaJIT-2.0.5

# 安装lua-cjson
ADD ./build/lua-cjson-2.1.0.tar.gz /opt/
RUN cd /opt/lua-cjson-2.1.0 && \
    cc -c -O3 -Wall -pedantic -DNDEBUG -I/usr/local/include/luajit-2.0/ -fpic -o lua_cjson.o lua_cjson.c \
    && make -j4 && mkdir -p /usr/local/lib/lua/5.2/ && cp -rf cjson.so /usr/local/lib/lua/5.2/ && rm -rf /opt/lua-cjson-2.1.0

# Limits Configuration
COPY ./build/freeswitch.limits.conf /etc/security/limits.d/

# 添加启动文件
ADD ./docker-entrypoint.sh /opt/docker-entrypoint.sh
RUN chmod +x /opt/docker-entrypoint.sh

SHELL ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD  /usr/local/freeswitch/bin/fs_cli -x status | grep -q ^UP || exit 1

ENTRYPOINT ["/opt/docker-entrypoint.sh"]

CMD ["/usr/local/freeswitch/bin/freeswitch"]