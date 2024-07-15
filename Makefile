SHELL = /bin/bash
VERSION = 1.10.11

all:
	echo Hi

setup:
	if [[ ! -f .env ]]; then \
		cp env.example .env; \
	fi

pull:
	docker pull registry.cn-shanghai.aliyuncs.com/xswitch/freeswitch:${VERSION}

.PHONY conf:
	docker cp xswitch:/usr/local/freeswitch/conf .

eject: conf
	echo conf copied to local dir, please edit docker-compose.yml to use it

build:
	docker build --build-arg VERSION=$(VERSION) -t xswitch:${VERSION} .  

build-macos:
	docker buildx build --build-arg VERSION=$(VERSION) --platform=linux/amd64 -t xswitch:${VERSION} . 

push:
	docker tag xswitch:${VERSION} registry.cn-shanghai.aliyuncs.com/xswitch/freeswitch:${VERSION}
	docker push registry.cn-shanghai.aliyuncs.com/xswitch/freeswitch:${VERSION}

login:
	docker login --username=wangganglab registry.cn-shanghai.aliyuncs.com

get-ip:
	curl ifconfig.me