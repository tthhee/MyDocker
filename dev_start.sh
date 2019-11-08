#!/usr/bin/env bash

CURRENT_ROOT_DIR="$(pwd)"

VERSION=""
ARCH=$(uname -m)
VERSION_X86_64="loc_dev-x86_64-latest"
VERSION_AARCH64="loc_dev-aarch64-latest"
if [ $ARCH == "x86_64" ]; then
    VERSION=$VERSION_X86_64
elif [ $ARCH == "aarch64" ]; then
    VERSION=$VERSION_AARCH64
else
    echo "Unknown architecture: $ARCH"
    exit 0
fi

DOCKER_REPO="hub.baidubce.com/apollo-11/internal"
#IMG=$DOCKER_REPO:$VERSION
IMG="tthhee/ubuntu14.04-bd:loc"

function container_running() {
    name=$1
    docker ps -a --format "{{.Names}}" | grep "$name" > /dev/null
    return $?
}

function main(){
    echo "/home/caros/corefiles/core_%e_%t.%p" | sudo tee /proc/sys/kernel/core_pattern
    docker login -u tthhee -p 'fxytobeno.1ok'
    echo "start to pull image : docker pull $IMG "
    docker pull $IMG
    if [ $? -ne 0 ];
    then
        echo "failed to pull dev image, pls run cmd and rety: docker pull $IMG"
        exit 1
    fi
    
    if container_running "loc_dev"; then
        docker stop loc_dev 1>/dev/null
        docker rm -f loc_dev 1>/dev/null
    fi
    
    # create mount point for params
    if [ ! -d "$HOME/adu" ]; then
      mkdir -p "$HOME/adu"
    fi
    if [ ! -d "$HOME/adu_data" ]; then
      mkdir -p "$HOME/adu_data"
    fi
    if [ ! -d "$HOME/cybertron" ]; then
      mkdir -p "$HOME/cybertron"
    fi
    if [ ! -d "$HOME/xlog" ]; then
      mkdir -p "$HOME/xlog"
    fi
    if [ ! -d "$HOME/corefiles" ]; then
      mkdir -p "$HOME/corefiles"
    fi

    USER_ID=$(id -u)
    GRP_ID=$(id -g)
    DOCKER_USER=caros
    DOCKER_GRP=caros
    DOCKER_HOME="/home/caros"
    if [ $USER_ID -eq 0 ];then 
        DOCKER_USER=root
        DOCKER_GRP=root
        DOCKER_HOME="/root"
    fi
    set -x
    docker run -it \
        -d \
        --privileged \
        --name loc_dev \
        -v $CURRENT_ROOT_DIR:/loc:rw \
        -v $HOME/adu:$DOCKER_HOME/adu:rw \
        -v $HOME/adu_data:$DOCKER_HOME/adu_data:rw \
        -v $HOME/cybertron:$DOCKER_HOME/cybertron:rw \
        -v $HOME/xlog:$DOCKER_HOME/xlog:rw \
        -v $HOME/corefiles:$DOCKER_HOME/corefiles:rw \
        -v $HOME/.ssh:$DOCKER_HOME/.ssh:rw \
        -v /etc/localtime:/etc/localtime:ro \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -e DISPLAY=unix$DISPLAY \
	--net host \
	-w /loc \
        --shm-size 2G \
        --add-host computing:127.0.0.1 \
        --hostname computing\
        $IMG \
        /bin/bash
    set +x

    if [ ! $USER_ID -eq 0 ];then 
        docker exec loc_dev bash -c "addgroup --gid $GRP_ID $DOCKER_GRP"
        docker exec loc_dev bash -c "adduser --disabled-password --force-badname --gecos '' $DOCKER_USER --uid $USER_ID --gid $GRP_ID  2>/dev/null"
        docker exec loc_dev bash -c "usermod -aG sudo $DOCKER_USER"
        docker exec loc_dev bash -c "usermod -aG dialout $DOCKER_USER"
        docker exec loc_dev bash -c "echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
        docker exec loc_dev bash -c "chown root:root /usr/bin/sudo"
        docker exec loc_dev bash -c "chmod 4755 /usr/bin/sudo"
        docker exec loc_dev bash -c "cp /etc/skel/. $DOCKER_HOME -r"
        docker exec loc_dev bash -c "chmod 777 /tmp"
        docker exec loc_dev bash -c "chown -R $DOCKER_USER:$DOCKER_USER $DOCKER_HOME"
    fi
    docker exec loc_dev bash -c "echo "/home/caros/corefiles/mainboard_%e_%t.%p" | sudo tee /proc/sys/kernel/core_pattern"
    docker exec loc_dev bash -c "mkdir /var/log/caros && chown -R $DOCKER_USER:$DOCKER_USER /var/log/caros"
    docker exec loc_dev bash -c "echo 'if [ -f "/loc/output/loc/setup.bash" ]; then source /loc/output/loc/setup.bash' >> $DOCKER_HOME/.bashrc"
    docker exec loc_dev bash -c "echo 'fi' >> $DOCKER_HOME/.bashrc"
    docker exec loc_dev bash -c "echo 'if [ -f "$DOCKER_HOME/adu/car-env.sh" ]; then source $DOCKER_HOME/adu/car-env.sh' >> $DOCKER_HOME/.bashrc"
    docker exec loc_dev bash -c "echo 'fi' >> $DOCKER_HOME/.bashrc"
    docker exec loc_dev bash -c "echo 'ulimit -c unlimited' >> $DOCKER_HOME/.bashrc"
    
}

main
