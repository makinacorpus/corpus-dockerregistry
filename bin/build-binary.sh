#!/usr/bin/env bash
changeset="${changeset:-v2.1.1}"
user=$(whoami)
binary="registry"
set -ex
cd "$(dirname $0)/.."
W="$(pwd)"
binaries="$W/binaries"
if [ ! -d distribution ];then
    git clone https://github.com/docker/distribution.git distribution
fi
cd distribution
git pull
git reset --hard $changeset
name="docker${binary}registrybuilder$(git log -n1 --pretty=format:"%h")"
sudo docker build --rm -t "$name" .
sudo docker rm -f "$name" || /bin/true
sudo docker run --name="$name" --entrypoint=/bin/true "$name"
sudo docker cp "$name":/go/bin/${binary} "$binaries/${binary}-${changeset}"
sudo docker rm -f "$name" || /bin/true
sudo docker rmi -f "$name" || /bin/true
sudo chown ${user} "$binaries/${binary}-${changeset}"
if [ ! -d "$binaries" ];then mkdir -p "$binaries";fi
if [ -f "$binaries/${binary}-${changeset}.xz" ];then
    rm -f "$binaries/${binary}-${changeset}.xz"
fi
xz -v -9e -z "$binaries/${binary}-${changeset}"
md5sum "$binaries/${binary}-${changeset}.xz" >\
    "$binaries/${binary}-${changeset}.xz.md5"
# vim:set et sts=4 ts=4 tw=80:
