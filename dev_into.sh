#!/usr/bin/env bash
USER=caros
if [ $(id -u) -eq 0 ];then
    USER=root
fi
xhost +local:root 1>/dev/null 2>&1
docker exec \
    -u $USER \
    -it loc_dev\
    /bin/bash -c "export COLUMNS=200; exec bash"
xhost -local:root 1>/dev/null 2>&1
