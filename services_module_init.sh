#!/bin/bash
#

#该脚本作用：为执行CD环节的目标机器上安装必要的应用，包括docker、docker-compose、ansible、mysql、redis、nginx、git

#定义redis密码
REDIS_PASS=''

cicd_docker(){
	docker --version &> /dev/null
	[ $? -eq 0 ] && echo "docker已安装完毕" && return 0
	yum install -y docker
	sed -i -e '18s@dockerd-current@dockerd-current --registry-mirror=https://jxus37ad.mirror.aliyuncs.com@' /usr/lib/systemd/system/docker.service
	echo '{ "insecure-registries": ["docker.listcloud.cn:5000","docker.ops.colourlife.com:5000"] }' > /etc/docker/daemon.json
	systemctl start docker
	systemctl enable docker
}

cicd_docker_compose(){
	docker-compose --version &> /dev/null
	[ $? -eq 0 ] && echo "docker-compose安装完毕" && return 0
	yum install -y docker-compose
	docker-compose --version &> /dev/null
	[ $? -eq 0 ] && echo "docker-compose安装完毕" && return 0
	pip -V  &> /dev/null
	if [ $? -eq 0 ];then
		yum remove -y docker-compose
		pip install docker-compose==1.17.1
        	#pip install docker-compose
	else
		yum remove -y docker-compose
        	yum -y install epel-release
        	yum install python-pip -y
        	pip install --upgrade pip
        	#pip install docker-compose
		pip install docker-compose==1.17.1
	fi
	docker-compose --version &> /dev/null
	if [ $? -eq 0 ];then
        	echo "docker-compose安装完毕"
	else
        	echo "docker-compose安装失败，且该脚本无法正常安装，请手动安装"
	fi
	#[ $? -ne 0 ] && curl -L https://github.com/docker/compose/releases/download/1.1.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && docker-compose --version && [ $? -ne 0 ] && echo "docker-compose安装失败" 
}

cicd_docker_ansible(){
	ansible --version &> /dev/null
	[ $? -eq 0 ] && echo "ansible已安装完毕" && return 0
	yum install -y ansible
}

cicd_mysql(){
	mysql --version &> /dev/null
	[ $? -eq 0 ] && echo "MySQL已安装完毕" && return 0
	wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
	rpm -ivh mysql-community-release-el7-5.noarch.rpm
	yum install mysql-community-server mysql -y
	systemctl start mysqld
	systemctl enable mysqld
	echo "请初始化MySQL"
}

cicd_redis(){
	redis-server --version  &> /dev/null
	[ $? -eq 0 ] && echo "redis已安装完毕" && return 0
	yum install -y redis && [ $? -ne 0 ] && echo "没有对应的yum源，请添加"
	echo "requirepass $REDIS_PASS" >> /etc/redis.conf
	docker ps &> /dev/null
	[ $? -eq 0 ] && DOCKER_INET=`ifconfig| grep -A1 docker0 |tail -1 |awk '{print $2}'` && sed -i "50,70s/bind 127.0.0.1/bind 127.0.0.1 $DOCKER_INET/" /etc/redis.conf
	systemctl start redis
	systemctl enable redis
}

cicd_nginx(){
	nginx -v &> /dev/null
	[ $? -eq 0 ] && echo "nginx已安装完毕" && return 0
	yum install -y nginx
	systemctl start nginx
	systemctl enable nginx
}

cicd_git(){
	git --version  &> /dev/null
	[ $? -eq 0 ] && echo "git已安装完毕" && return 0
	yum install -y git
}

#安装docker
cicd_docker
#安装docker-compose
cicd_docker_compose
#安装ansible
cicd_docker_ansible
#安装mysql
cicd_mysql
#安装redis
cicd_redis
#安装nginx
cicd_nginx
#安装git
cicd_git
