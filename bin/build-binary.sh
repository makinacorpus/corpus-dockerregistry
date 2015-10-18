#!/usr/bin/env bash
changeset="${changeset:-v2.1.1}"
user=$(whoami)
set -ex
cd "$(dirname $0)/.."
if [ ! -d distribution ];then
    git clone https://github.com/docker/distribution.git distribution
fi
cd distribution
git pull
git reset --hard $changeset
name=dockerregistrybuilder
cp Dockerfile dockerfile.a
sed "/^ENTRYPOINT/d" -i dockerfile.a
sed "/^CMD/d" -i dockerfile.a
sudo docker build --rm -t "$name" -f dockerfile.a .
sudo docker run --name="$name" "$name" /bin/true
sudo docker cp "$name":/go/bin/registry "../registry-${changeset}"
sudo chown ${user} "../registry-${changeset}"
sudo docker rm -f "$name"
cd ..
if [ -f registry-${changeset}.xz ];then
    rm -f registry-${changeset}.xz
fi
xz -v -9e -z registry-${changeset}
md5sum registry-${changeset}.xz > registry-${changeset}.xz.md5
# vim:set et sts=4 ts=4 tw=80:
