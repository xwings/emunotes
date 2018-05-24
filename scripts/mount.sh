#!/bin/sh

model="$1"
modeldir="/opt/$model"


if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root"
   exit 1
fi

if [ $# -eq 0 ];then
    echo "Error: No arguments supplied"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
fi

if [ ! -d $modeldir ]; then
    echo "Error: Model not found"
    exit 1
fi

cd $modeldir

if [ ! -d $modeldir/proc ] || [ ! -d $modeldir/sys ] || [ ! -d $modeldir/dev ]; then
    echo "create proc sys dev"
    mkdir proc sys dev
fi

mount -t proc proc proc/
mount --rbind /sys sys/
mount --rbind /dev dev/
