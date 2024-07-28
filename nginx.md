首先，从GitHub仓库下载nginx.sh脚本：
wget https://raw.githubusercontent.com/helloxz/nginx-cdn/master/nginx.sh
接下来，授予脚本执行权限并运行它：
chmod + x nginx.sh
重写 nginx.sh
脚本会自动检测系统版本并根据系统类型（CentOS 6或CentOS 7）选择编译安装或二进制安装。编译安装大约需要10分钟，而二进制安装通常需要2分钟左右。

安装完成后，执行以下命令使环境变量立即生效，或者重新打开终端：

源 /etc/profile
现在，你可以使用以下命令来管理Nginx：
启动Nginx：nginx
停止Nginx：nginx -s stop
重载Nginx配置：nginx -s reload
查看Nginx配置语法：nginx -t
