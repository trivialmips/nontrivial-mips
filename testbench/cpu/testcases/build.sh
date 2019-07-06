#!/bin/bash

. /etc/os-release

case $NAME in
"Arch Linux")
    ARCH=mipsel-linux-musln32 make mem
    ;;
"Ubuntu")
    ARCH=mipsel-linux-gnu make mem
    ;;
esac
