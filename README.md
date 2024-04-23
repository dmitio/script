1.修改ssh端口为9527
```
bash -c "$(wget -qO- https://raw.githubusercontent.com/dmitio/script/main/root.sh)"
```

2.安装Docker
```
wget -qO- https://raw.githubusercontent.com/dmitio/script/main/setup.sh | bash

```
3.Sing-box全家桶
```
bash <(wget -qO- https://raw.githubusercontent.com/dmitio/script/main/singbox.sh)

```
4.3x-ui
```
bash <(curl -Ls https://raw.githubusercontent.com/dmitio/script/main/3xui.sh)

```
5.naiveproxy
```
wget -N --no-check-certificate https://raw.githubusercontent.com/dmitio/script/main/naiveproxy.sh && bash naiveproxy.sh
```
