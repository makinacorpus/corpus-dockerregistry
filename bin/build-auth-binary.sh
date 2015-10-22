#!/usr/bin/env bash
changeset="${changeset:-"e3e2d6"}"
user=$(whoami)
binary="auth_server"
set -ex
cd $(dirname $0)/..
W="$(pwd)"
DATA="${DATA:-"${W}_data"}"
if [ ! -d $DATA/docker_auth ];then
    git clone https://github.com/cesanta/docker_auth.git $DATA/docker_auth
fi
cd $DATA/docker_auth
git pull
git reset --hard $changeset
name="docker${binary}registrybuilder$(git log -n1 --pretty=format:"%h")"
sudo docker rm -f "$name" || /bin/true
sudo docker run --rm --name="$name" \
    -v $PWD:/go/src/github.com/cesanta/docker_auth\
    -v $DATA/go:/go\
    -w /go/src/github.com/cesanta/docker_auth/auth_server\
    golang:1.5 make update-deps build
cd $W
if [ ! -d binaries ];then mkdir -p binaries;fi
sudo cp $DATA/go/bin/${binary} "binaries/${binary}-${changeset}"
sudo chown ${user} "binaries/${binary}-${changeset}"
sudo docker rm -f "$name" || /bin/true
if [ -f "binaries/${binary}-${changeset}.xz" ];then
    rm -f "binaries/${binary}-${changeset}.xz"
fi
xz -v -9e -z "binaries/${binary}-${changeset}"
md5sum "binaries/${binary}-${changeset}.xz" >\
    "binaries/${binary}-${changeset}.xz.md5"
# vim:set et sts=4 ts=4 tw=80:
