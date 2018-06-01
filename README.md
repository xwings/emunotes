#Note for compiling gdb

```
sudo apt-get install libreadline-dev texinfo
./configure --prefix=/opt/gdb --with-python --with-system-readline && make -j4 && make -j4 install
```

#Note for compiling qemu
```
./configure --target-list=arm-softmmu,mips-softmmu,mips64-softmmu,mips64el-softmmu,mipsel-softmmu,aarch64-softmmu,arm-linux-user,aarch64-linux-user,mips64el-linux-user,mipsel-linux-user,mips-linux-user,mips64-linux-user --prefix=/opt/qemu --python=/usr/bin/python2.7
```

# rc.local for debian

```
#!/bin/bash

# some config for tenda/ maybe some other routers
swapon /dev/sda5

ip link add link br0 name vlan0 type vlan id 0
ifconfig eth1 up
ifconfig vlan0 up

exit 0
```

# activate rc.local for debian
```
chmod +x /etc/rc.local
systemctl enable rc-local
systemctl start rc-local.service
```


# Boot up ARM

URL: http://ftp.cn.debian.org/debian/dists/stretch/main/installer-armhf/current/images/netboot/
URL: http://ftp.nl.debian.org/debian/dists/stretch/main/installer-armhf/current/images/netboot/

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


sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1022 -j DNAT --to-destination 10.253.253.10:22
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1080 -j DNAT --to-destination 10.253.253.10:80
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 10443 -j DNAT --to-destination 10.253.253.10:443

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

sudo iptables -t nat -A POSTROUTING -o ens33 -j MASQUERADE
sudo iptables -I FORWARD 1 -i tap0 -j ACCEPT
sudo iptables -I FORWARD 1 -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1122 -j DNAT --to-destination 10.253.253.11:22
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 1180 -j DNAT --to-destination 10.253.253.11:80
sudo iptables -t nat -A PREROUTING -i ens33 -p tcp --dport 11443 -j DNAT --to-destination 10.253.253.11:443


## run

sudo screen -dm /opt/qemu/bin/qemu-system-mipsel -m 512 -M malta -kernel boot.stretch.mipsel/vmlinux-4.9.0-4-4kc-malta -initrd boot.stretch.mipsel/initrd.img-4.9.0-4-4kc-malta -append "root=/dev/sda1 net.ifnames=0 biosdevname=0 nokaslr" -hda debian-stretch.mipsel.qcow2 -net nic -net tap,ifname=tap0,script=no,downscript=no -net nic -net tap,ifname=tap1,script=no,downscript=no -nographic

```

# Mount Image

Note: 2048 * 512 = 1048576 for mounting boot

```
$ sudo fdisk -lu debian-jessie.img
Disk debian-jessie.img: 8 GiB, 8589934592 bytes, 16777216 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x0cb4077d

Device             Boot    Start      End  Sectors  Size Id Type
debian-jessie.img1 *        2048   499711   497664  243M 83 Linux
debian-jessie.img2        499712 15958015 15458304  7.4G 83 Linux
debian-jessie.img3      15960062 16775167   815106  398M  5 Extended
debian-jessie.img5      15960064 16775167   815104  398M 82 Linux swap / Solaris

```
```
sudo mount -o loop,offset=1048576 debian-stretch.mipsel.img tmp/
```

# Installation
```
apt-get install python2.7 python-pip python-dev git libssl-dev libffi-dev build-essential
pip install --upgrade pip
pip install --upgrade pwntools
pip install --upgrade ropper
```

# mount proc
```
cd /opt/acXX
mkdir proc sys dev
mount -t proc proc proc/
mount --rbind /sys sys/
mount --rbind /dev dev/
cd /opt
chroot /opt/acXX /bin/sh
```

# network
```
source /etc/network/interfaces.d/*

# The loopback network interface
auto lo br0
iface lo inet loopback

# The primary network interface
#allow-hotplug enp0s11
#iface enp0s11 inet static
#       address 10.253.253.10/24
#       gateway 10.253.253.254
        # dns-* options are implemented by the resolvconf package, if installed#
#       dns-nameservers 10.10.18.254


iface br0 inet static
        bridge_ports eth0
        address 10.253.253.11/24
            gateway 10.253.253.254
        # dns-* options are implemented by the resolvconf package, if installed
        dns-nameservers 10.10.18.254

iface vlan1 inet static
    vlan-raw-device br0
    #address 192.168.1.1
    #netmask 255.255.255.0
```
