#!/bin/sh

model="$1"
modeldir="/opt/$model"

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
fi

if [ ! -d $modeldir ]; then
    echo "model not found"
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
