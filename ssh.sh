#!/bin/bash

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
