#Note for compiling gdb

```
sudo apt-get install libreadline-dev texinfo
./configure --prefix=/opt/gdb --with-python --with-system-readline && make -j4 && make -j4 install
```

#Note for compiling qemu
```
./configure --target-list=arm-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,aarch64-softmmu,arm-linux-user,aarch64-linux-user,mips64el-linux-user,mipsel-linux-user,mips-linux-user,mips64-linux-user --prefix=/opt/qemu --python=/usr/bin/python2.7
```

# Boot up ARM
```
#!/bin/bash

sudo tunctl -d tap0

sudo screen -dm /opt/qemu/bin/qemu-system-arm -m 2048 -M virt -cpu cortex-a15 -smp cpus=4,maxcpus=4 -kernel boot.stretch.armhf.virt/vmlinuz-4.9.0-6-armmp-lpae -initrd boot.stretch.armhf.virt/initrd.img-4.9.0-6-armmp-lpae -append "root=/dev/vda2" -drive file=debian-stretch.armhf_virt.qcow2,if=none,format=qcow2,id=hd0 -device virtio-blk-device,drive=hd0 -netdev type=tap,id=net0 -device virtio-net-device,netdev=net0,mac=52:54:00:fa:ee:10 -nographic

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

sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1022 -j DNAT --to-destination 10.253.253.11:22
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1080 -j DNAT --to-destination 10.253.253.11:80
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 10443 -j DNAT --to-destination 10.253.253.11:443

echo "Booting VM, eta 10 seconds"
sleep 10
sudo ifconfig tap0 10.253.253.254 netmask 255.255.255.0
```


# Boot MIPS
```
#!/bin/bash

sudo tunctl -t tap0 -u xwings
sudo ifconfig tap0 10.253.253.254 netmask 255.255.255.0

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

sudo iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 1122 -j DNAT --to-destination 10.253.253.11:22
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 1180 -j DNAT --to-destination 10.253.253.11:80
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 11443 -j DNAT --to-destination 10.253.253.11:443


# run image
sudo screen -dm /opt/qemu/bin/qemu-system-mipsel -m 1024 -M malta -kernel boot.stretch.mipsel/vmlinux-4.9.0-4-4kc-malta -initrd boot.stretch.mipsel/initrd.img-4.9.0-4-4kc-malta -append "console=ttyS0 root=/dev/sda1" -hda debian-stretch.mipsel.qcow2 -net nic -net tap,ifname=tap0,script=no,downscript=no -nographic

```

# Installation
```
apt-get install python2.7 python-pip python-dev git libssl-dev libffi-dev build-essential
pip install --upgrade pip
pip install --upgrade pwntools
pip install --upgrade ropper
```


