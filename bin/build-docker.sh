#!/usr/bin/env bash
set -ex
cd "$(dirname $0)/.."
changeset="${changeset:-$(grep '"docker":' -A1 .salt/PILLAR.sample |grep changeset|awk '{print $2}'|sed 's/"//g')}"
user=$(whoami)
binary="docker"
W="$(pwd)"
URL="https://github.com/makinacorpus/docker"
DATA="${DATA:-"${W}_data"}"
binaries="$W/binaries"
if [ ! -d "${DATA}/${binary}" ];then git clone "${URL}" "${DATA}/${binary}";fi
cd "${DATA}/${binary}"
git fetch --all;git reset --hard remotes/origin/$changeset
docker="docker${binary}builder${changeset}"
if [ "x\$(sudo docker images -aq docker)" = "x0" ];then
    sudo docker build -t docker .
fi
cat | sudo bash << EOF
set -ex
docker rm -f $docker || /bin/true
docker run --name=$docker --rm --privileged -v "\$(pwd):/go/src/github.com/docker/docker" docker hack/make.sh binary ubuntu
binaryp=\$(readlink -f bundles/${changeset}/binary/docker)
if [ ! -d $binaries ];then mkdir -p $binaries;fi
if [ -f "$binaries/${binary}-${changeset}.xz" ];then
    sudo rm -f "$binaries/${binary}-${changeset}.xz"
fi
cp "\${binaryp}" "$binaries/${binary}-${changeset}"
xz -v -9e -z "$binaries/${binary}-${changeset}"
md5sum "$binaries/${binary}-${changeset}.xz" > "$binaries/${binary}-${changeset}.xz.md5"
chown -Rf ${user} $binaries $W/.git

EOF
# vim:set et sts=4 ts=4 tw=80:
