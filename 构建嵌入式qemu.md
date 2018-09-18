---
title: 构建嵌入式qemu
date: 2018-09-17 11:27:15
tags:
---



整体的思路是先编译安装好qemu，从网上下载kernel和initrd用于安装系统，将系统安装在我们创建的硬盘镜像中，由于没有grub我们需要从img中提取出initrd用于系统的boot。提取出后通过kernel、initrd和安装好的filesystem运行程序。

<!-- more-->

## 编译安装qemu 

为了避免一些依赖兼容性的问题，我用一个新建的ubuntu18.04做容器。

首先从github上下载qemu。

```
git clone https://github.com/qemu/qemu.git
```

在安装前需要装一些依赖：

```
sudo apt-get install build-essential zlib1g-dev pkg-config libglib2.0-dev binutils-dev libboost-all-dev autoconf libtool libssl-dev libpixman-1-dev libpython-dev python-pip python-capstone virtualenv bison flex
```

编译时的配置信息如下（选了一大堆架构列表，把qemu装在/opt/qemu中）：

```
./configure --target-list=arm-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,aarch64-softmmu,arm-linux-user,aarch64-linux-user,mips64el-linux-user,mipsel-linux-user,mips-linux-user,mips64-linux-user --prefix=/opt/qemu --python=/usr/bin/python2.7
```

然后`make && sudo make install `一把梭。

装完之后可能还有一些工具没有安装完全，这时候再apt-get安装一次qemu。

## 安装系统

首先我们需要从网上下载kernel和initrd。去镜像站就可以下载到，比如（我这里用的ubuntu的来安装）：

```
https://mirrors.tuna.tsinghua.edu.cn/debian/dists/buster/main/installer-armhf/current/images/netboot/
```

创建一个空的filesystem：

```
qemu-img create -f qcow2 ubuntu.img 16G
```

现在我们拿到了kernel、initrd和新的硬盘镜像了，然后需要在qemu里面安装系统了，我的安装方法如下，记得append时要把filesystem的地址改成ram，原因是要把驱动安装程序放在内存中运行，kernel和initrd指定之前下载好的就好（注意内存设置的不要比虚拟机大否则会崩掉）：

```
sudo /opt/qemu/bin/qemu-system-arm -m 1024 -M virt -cpu cortex-a15 -smp cpus=4,maxcpus=4 -kernel /home/spike/vmlinuz -initrd /home/spike/initrd.gz -append "root=/dev/ram" -drive file=/home/spike/ubuntu.img,if=none,format=qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -netdev type=tap,id=net0 -device virtio-net-device,netdev=net0,mac=52:54:00:fa:ee:10 -nographic
```

在安装时，会遇到需要网络的情况（安装一半会卡住），我们需要手动配置一下网络，这里我们看到我们的网卡名字是enp0s25（这个改成自己的），qemu运行后开启的网卡名字叫tap0，我们配置一下tap0的iptables，并设置好ip。这里注意一下需要先启动qemu，我们修改qemu创建的接口（tap0），如果我们自己创建一个tap0的话qemu运行时不会直接使用这个tap0，会重新创建一个tap1：

```
sudo sysctl -w net.ipv4.ip_forward=1

sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# inet_ip = 192.168.100.2
sudo ifconfig tap0 192.168.100.254 netmask 255.255.255.0
```

运行这些命令后qemu里面才能上网

然后在qemu的安装界面，我们配置一下固定的IP，就是脚本里面改的IP(任意一个C段网都行，不要和宿主机的网段一样就好，这里配成了192.168.100.2)。网关填写tap0的地址，DNS设置自己的DNS，如果不知道就设置成8.8.8.8或114.114.114.114。

安装要过很久，建议晚上睡前安，第二天收割img。

安装好了后会有提示系统没法boot，这是正常的，毕竟我们没有grub，直接退出安装就好了。



## 启动安装好的系统

由于我们没有grub帮助我们boot，所以我门需要把initrd从qcow2中提取出来，单独指定给qemu。这是我们需要一个工具`libguestfs-tools`。apt一把梭。

```
sudo apt-get install libguestfs-tools -yf
```

用virt-ls看一下initrd的文件名（别问我问啥要加这两个环境变量，log提示我加的）：

```
LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1 sudo virt-ls ubuntu.img /boot/
```

然后把initrd copy出来

```
LIBGUESTFS_DEBUG=1 LIBGUESTFS_TRACE=1 sudo virt-copy-out -a ubuntu.img /boot/initrd.img-4.4.0-135-generic-lpae ./
```

后面我们就用拷贝出来的initrd，安装好的filesystem——ubunut.img，以及kernel将ubuntu运行起来。

```
sudo /opt/qemu/bin/qemu-system-arm -m 1024 -M virt -cpu cortex-a15 -smp cpus=4,maxcpus=4 -kernel ./vmlinuz -initrd ./initrd.img-4.4.0-135-generic-lpae -append "root=/dev/vda2" -drive file=./ubuntu.img,if=none,format=qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -netdev type=tap,id=net0 -device virtio-net-device,netdev=net0,mac=52:54:00:fa:ee:10 -nographic
```

这里把root改成/dev/vda2，从硬盘中得到filesystem。运行后我们还是需要修改一下tap0的iptables和网络配置(nat映射神马的，这样外网可以访问)：

```
#!/bin/bash

sudo sysctl -w net.ipv4.ip_forward=1

echo "Stopping firewall and allowing everyone..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

sudo iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

inet_ip=192.168.100.2

sudo iptables -t nat -A PREROUTING -i enp0s25 -p tcp --dport 1022 -j DNAT --to-destination $inet_ip:22
sudo iptables -t nat -A PREROUTING -i enp0s25 -p tcp --dport 1080 -j DNAT --to-destination $inet_ip:80
sudo iptables -t nat -A PREROUTING -i enp0s25 -p tcp --dport 10443 -j DNAT --to-destination $inet_ip:443

echo "Booting VM, eta 10 seconds"
sleep 10
sudo ifconfig tap0 192.168.100.254 netmask 255.255.255.0
```



到这里我们的嵌入式虚拟环境就搭建好了。