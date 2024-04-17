#!/bin/bash

# 定义函数：修改SSH端口号
modify_ssh_port() {
    # 检测防火墙是否开启
    if systemctl is-active --quiet firewalld.service; then
        echo "警告：防火墙已开启，请确保已放行新端口号"
        exit 1
    fi

    # 确认操作，默认回车继续
    read -p "即将修改SSH端口号为9527，是否继续？[Y/n]: " confirm
    confirm=${confirm:-Y}
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 1
    fi

    # 设置SSH端口为9527
    new_port=9527

    # 备份原来的SSH配置文件
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # 修改SSH配置文件中的端口号
    sed -i "s/#Port 22/Port $new_port/g" /etc/ssh/sshd_config

    # 重启SSH服务
    systemctl restart sshd.service

    echo "已成功修改SSH端口为$new_port，请确保已放行$new_port端口"
}

# 执行修改SSH端口号函数
modify_ssh_port

# 下载脚本文件
wget -O root.sh https://raw.githubusercontent.com/dmitio/script/main/root.sh

# 检查是否成功下载脚本文件
if [ $? -ne 0 ]; then
    echo "下载脚本文件失败"
    exit 1
fi

# 给予执行权限
chmod +x root.sh

# 执行脚本
./root.sh

# 清空屏幕
clear

