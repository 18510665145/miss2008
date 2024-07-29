#!/bin/bash
############### CentOS一键安装Nginx脚本 ###############
#Author:missrian2008
#Update:2024-7-29

####################### END #######################

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

dir='/usr/local/'
nginx_version='1.18'
openssl_version='1.1.1g'
pcre_version='8.43'

# 函数定义
function check_os() {
    if test -e "/etc/redhat-release"; then
        yum -y install gcc gcc-c++ perl unzip libmaxminddb-devel gd-devel
    elif test -e "/etc/debian_version"; then
        apt-get -y update
        apt-get -y install curl wget perl unzip build-essential libmaxminddb-dev libgd-dev
    else
        echo "当前系统不支持！"
    fi
}

function get_ip() {
    osip=$(curl -4s https://api.ip.sb/ip)
    echo $osip
}

function chk_firewall() {
    if [ -e "/etc/sysconfig/iptables" ]; then
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp --dport 443 -j ACCEPT
        service iptables save
        service iptables restart
    else
        firewall-cmd --zone=public --add-port=80/tcp --permanent
        firewall-cmd --zone=public --add-port=443/tcp --permanent
        firewall-cmd --reload
    fi
}

function DelPort() {
    if [ -e "/etc/sysconfig/iptables" ]; then
        sed -i '/^.*80/d' /etc/sysconfig/iptables
        sed -i '/^.*443/d' /etc/sysconfig/iptables
        service iptables save
        service iptables restart
    else
        firewall-cmd --zone=public --remove-port=80/tcp --permanent
        firewall-cmd --zone=public --remove-port=443/tcp --permanent
        firewall-cmd --reload
    fi
}

function depend() {
    cd ${dir}
    wget --no-check-certificate https://ftp.pcre.org/pub/pcre/pcre-${pcre_version}.tar.gz
    tar -zxvf pcre-${pcre_version}.tar.gz
    cd pcre-${pcre_version}
    ./configure
    make -j4 && make -j4 install

    cd ${dir}
    wget http://soft.xiaoz.org/linux/zlib-1.2.11.tar.gz
    tar -zxvf zlib-1.2.11.tar.gz
    cd zlib-1.2.11
    ./configure
    make -j4 && make -j4 install

    cd ${dir}
    wget --no-check-certificate -O openssl.tar.gz https://www.openssl.org/source/openssl-${openssl_version}.tar.gz
    tar -zxvf openssl.tar.gz
    cd openssl-${openssl_version}
    ./config
    make -j4 && make -j4 install
}

function install_service() {
    if [ -d "/etc/systemd/system" ]; then
        wget -P /etc/systemd/system https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.service
        systemctl daemon-reload
        systemctl enable nginx
    fi
}

function CompileInstall() {
    groupadd www
    useradd -M -g www www -s /sbin/nologin

    cd /usr/local
    wget http://soft.xiaoz.org/nginx/ngx_http_substitutions_filter_module.zip
    unzip ngx_http_substitutions_filter_module.zip

    cd /usr/local && wget http://soft.xiaoz.org/nginx/ngx_cache_purge-2.3.tar.gz
    tar -zxvf ngx_cache_purge-2.3.tar.gz
    mv ngx_cache_purge-2.3 ngx_cache_purge

    wget http://soft.xiaoz.org/nginx/ngx_brotli.tar.gz
    tar -zxvf nginx/ngx_brotli.tar.gz

    cd /usr/local
    wget https://wget.ovh/nginx/xcdn-${nginx_version}.tar.gz
    tar -zxvf xcdn-${nginx_version}.tar.gz
    cd xcdn-${nginx_version}
    ./configure --prefix=/usr/local/nginx --user=www --group=www \
    --with-stream \
    --with-http_stub_status_module \
    --with-http_v2_module \
    --with-http_ssl_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_slice_module \
    --with-http_image_filter_module=dynamic \
    --with-pcre=../pcre-${pcre_version} \
    --with-pcre-jit \
    --with-zlib=../zlib-1.2.11 \
    --with-openssl=../openssl-${openssl_version} \
    --add-module=../ngx_http_substitutions_filter_module \
    --add-module=../ngx_cache_purge \
    --add-module=../ngx_brotli \
    --add-dynamic-module=${dir}ngx_http_geoip2_module
    make -j4 && make -j4 install

    rm -rf ${dir}xcdn-1.*
    rm -rf ${dir}zlib-1.*
    rm -rf ${dir}pcre-8.*
    rm -rf ${dir}openssl*
    rm -rf ${dir}testcookie-nginx-module*
    rm -rf ${dir}ngx_http_geoip2_module*
    rm -rf ${dir}ngx_http_ipdb_module.zip
    rm -rf ${dir}ngx_http_substitutions_filter_module*
    rm -rf ${dir}ngx_cache_purge*
    rm -rf ${dir}ngx_brotli*
    rm -rf nginx.tar.gz
    rm -rf nginx.1
    cd
    rm -rf jemalloc*

    mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
    wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.conf -P /usr/local/nginx/conf/
    wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/etc/logrotate.d/nginx -P /etc/logrotate.d/
    mkdir -p /usr/local/nginx/conf/vhost
    mkdir -p /usr/local/nginx/conf/cdn
    /usr/local/nginx/sbin/nginx

    echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
    export PATH=$PATH:'/usr/local/nginx/sbin'

    install_service
    echo "------------------------------------------------"
    echo "XCDN installed successfully. Please visit the http://${osip}"
}

function BinaryInstall() {
    groupadd www
    useradd -M -g www www -s /sbin/nologin

    wget http://soft.xiaoz.org/nginx/xcdn-binary-${nginx_version}.tar.gz -O /usr/local/nginx.tar.gz
    cd /usr/local && tar -zxvf nginx.tar.gz

    wget --no-check-certificate https://raw.githubusercontent.com/helloxz/nginx-cdn/master/etc/logrotate.d/nginx -P /etc/logrotate.d/

    echo "export PATH=$PATH:/usr/local/nginx/sbin" >> /etc/profile
    export PATH=$PATH:'/usr/local/nginx/sbin'

    /usr/local/nginx/sbin/nginx
    install_service
    echo "------------------------------------------------"
    echo "XCDN installed successfully. Please visit the http://${osip}"
}

function uninstall() {
    pkill nginx
    userdel www && groupdel www
    cp -a /usr/local/nginx/conf/vhost /home/vhost_bak
    rm -rf /usr/local/nginx
    sed -i "s%:/usr/local/nginx/sbin%%g" /etc/profile
    sed -i '/^.*nginx/d' /etc/rc.d/rc.local
    rm -rf /etc/logrotate.d/nginx
}

# 选择安装方式
echo "------------------------------------------------"
echo "欢迎使用Nginx一键安装脚本^_^，请先选择安装方式："
echo "1) 编译安装，支持CentOS 6/7"
echo "2) 二进制安装，支持CentOS 7"
echo "3) 卸载Nginx"
echo "q) 退出！"
read -p ":" istype

case $istype in
    1)
        check_os
        get_ip
        chk_firewall
        depend
        CompileInstall
    ;;
    2)
        check_os
        get_ip
        chk_firewall
        BinaryInstall
    ;;
    3)
        uninstall
        DelPort
        echo 'Uninstall complete.'
    ;;
    q)
        exit
    ;;
    *)
        echo '参数错误！'
