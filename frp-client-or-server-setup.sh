#!/usr/bin/env bash

trap "rm -fr frp frp.tar.gz" EXIT

if [ "$1" != "frpc" ] && [ "$1" != "frps" ]; then
    echo >&2 "Usage"
    echo >&2 "For frp server: ./setup.sh frps"
    echo >&2 "For frp client: ./setup.sh frpc"
    exit 0
fi

command -v "$1" >/dev/null 2>&1 || {
    if [ "$(uname -m)" == 'x86_64' ]; then
        wget -c -O frp.tar.gz \
            https://github.com/fatedier/frp/releases/download/v0.33.0/frp_0.33.0_linux_amd64.tar.gz
    else
        wget -c -O frp.tar.gz \
            https://github.com/fatedier/frp/releases/download/v0.33.0/frp_0.33.0_linux_arm64.tar.gz
    fi

    mkdir frp
    tar -xzvf frp.tar.gz -C frp --strip-components 1

    sudo cp frp/"$1" /usr/bin
    sudo chmod +x /usr/bin/"$1"
    /usr/sbin/setcap cap_net_bind_service=+ep /usr/bin/"$1"

    sudo mkdir -p /etc/frp/
    sudo cp frp/"$1".ini /etc/frp/
    # alternate systemd service files
    # https://gist.github.com/ihipop/4dc607caef7c874209521b10d18e35af
    sudo cp frp/systemd/* /lib/systemd/system/

    sudo systemctl start "$1".service
    sudo systemctl start "$1"@.service
    sudo systemctl enable "$1".service
    sudo systemctl enable "$1"@.service

    echo "$1 is installed, started and enabled as service"
    echo "You can change configuration file here: /etc/frp/$1.ini"
    echo "Then, to apply new configuration run: sudo systemctl restart $1.service"
}
