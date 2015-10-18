#!/usr/bin/env bash
cd $(dirname $0)
W=$(pwd)
LEVEL="${LEVEL:-info}"
pillar="${pillar:-"${W}/../data/configuration/pillar.sls"}"
dpillar="${W}/../pillar/init.sls"
args="re_configure=true"
if [ -e "$pillar" ];then
    cp -fv "${pillar}" "${dpillar}"
fi
salt-call -l${LEVEL} --local mc_launcher.launch $args
# vim:set et sts=4 ts=4 tw=80:
