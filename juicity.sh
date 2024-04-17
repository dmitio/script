#!/bin/bash

# 判断系统及定义系统安装依赖方式
REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "fedora")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Fedora")
PACKAGE_UPDATE=("apt-get update" "apt-get update" "yum -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "yum -y install")
PACKAGE_REMOVE=("apt -y remove" "apt -y remove" "yum -y remove" "yum -y remove" "yum -y remove")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && echo "请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && echo "目前暂不支持你的VPS的操作系统！" && exit 1

if [[ -z $(type -P curl) ]]; then
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} curl
fi

archAffix(){
    case "$(uname -m)" in
        x86_64 | amd64 ) echo 'x86_64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        * ) echo "不支持的CPU架构!" && exit 1 ;;
    esac
}

instjuicity(){
    if [[ ! ${SYSTEM} == "CentOS" ]]; then
        ${PACKAGE_UPDATE}
        ${PACKAGE_INSTALL} bind-utils
    fi
    ${PACKAGE_INSTALL} wget curl sudo unzip dnsutils
    
    last_version=$(curl -Ls "https://api.github.com/repos/juicity/juicity/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') || last_version=v$(curl -Ls "https://data.jsdelivr.com/v1/package/resolve/gh/juicity/juicity" | grep '"version":' | sed -E 's/.*"([^"]+)".*/\1/')
    tmp_dir=$(mktemp -d)

    wget https://github.com/juicity/juicity/releases/download/$last_version/juicity-linux-$(archAffix).zip -O $tmp_dir/juicity.zip

    cd $tmp_dir
    unzip juicity.zip
    cp -f juicity-server /usr/bin/juicity-server
    cp -f juicity-server.service /etc/systemd/system/juicity-server.service

    if [[ -f "/usr/bin/juicity-server" && -f "/etc/systemd/system/juicity-server.service" ]]; then
        chmod +x /usr/bin/juicity-server /etc/systemd/system/juicity-server.service
        rm -f $tmp_dir/*
    else
        echo "Juicity 内核安装失败！"
        rm -f $tmp_dir/*
        exit 1
    fi

    green "Juicity 协议证书申请方式如下："
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 脚本自动申请 ${YELLOW}（默认）${PLAIN}"
    echo -e " ${GREEN}2.${PLAIN} 自定义证书路径"
    echo ""
    read -rp "请输入选项 [1-2]: " certInput
    if [[ $certInput == 2 ]]; then
        read -p "请输入公钥文件 crt 的路径：" cert_path
        echo "公钥文件 crt 的路径：$cert_path "
        read -p "请输入密钥文件 key 的路径：" key_path
        echo "密钥文件 key 的路径：$key_path "
        read -p "请输入证书的域名：" domain
        echo "证书域名：$domain"
    else
        cert_path="/root/cert.crt"
        key_path="/root/private.key"
        if [[ -f /root/cert.crt && -f /root/private.key ]] && [[ -s /root/cert.crt && -s /root/private.key ]] && [[ -f /root/ca.log ]]; then
            domain=$(cat /root/ca.log)
            green "检测到原有域名：$domain 的证书，正在应用"
        else
            WARPv4Status=$(curl -s4m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            WARPv6Status=$(curl -s6m8 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
            if [[ $WARPv4Status =~ on|plus ]] || [[ $WARPv6Status =~ on|plus ]]; then
                wg-quick down wgcf >/dev/null 2>&1
                systemctl stop warp-go >/dev/null 2>&1
                ip=$(curl -s4m8 ip.p3terx.com -k | sed -n 1p) || ip=$(curl -s6m8 ip.p3terx.com -k | sed -n 1p)
                wg-quick up wgcf >/dev/null 2>&1
                systemctl start warp-go >/dev/null 2>&1
            else
                ip=$(curl -s4m8 ip.p3terx.com -k | sed -n 1p) || ip=$(curl -s6m8 ip.p3terx.com -k | sed -n 1p)
            fi
            
            read -p "请输入需要申请证书的域名：" domain
            echo $domain > /root/ca.log
        fi
    fi

    mkdir -p /root/.acme.sh
    [[ ! -f /root/.acme.sh/acme.sh ]] && curl https://get.acme.sh | sh
    /root/.acme.sh/acme.sh --issue -d ${domain} --standalone
    /root/.acme.sh/acme.sh --install-cert -d ${domain} --key-file ${key_path} --fullchain-file ${cert_path}

    systemctl daemon-reload
    systemctl start juicity-server
    systemctl enable juicity-server

    green "Juicity 内核安装成功！"
}

removejuicity(){
    systemctl stop juicity-server
    systemctl disable juicity-server

    rm -f /usr/bin/juicity-server /etc/systemd/system/juicity-server.service
    green "Juicity 内核卸载成功！"
}

menu(){
    clear
    echo -e " ${GREEN}Juicity 内核管理脚本${PLAIN} ${RED}[v${CUR_VER}]${PLAIN}"
    echo -e " ----"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo -e " ${GREEN}1.${PLAIN} 安装 Juicity 内核"
    echo -e " ${GREEN}2.${PLAIN} 卸载 Juicity 内核"
    echo -e " ----"
    echo -n -e " 请选择 [0-2]: "
    read -r menu_num
    case $menu_num in
        0)
            exit 0
            ;;
        1)
            instjuicity
            ;;
        2)
            removejuicity
            ;;
        *)
            echo -e "${RED}请输入正确的数字${PLAIN}"
            ;;
    esac
}

menu
