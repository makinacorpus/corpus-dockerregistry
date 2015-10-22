#!/usr/bin/env bash
cd "$(dirname "${0}/..")"
W="$(pwd)"
DATA="${DATA:-"${W}_data"}"
LEVEL="${LEVEL:-info}"
pillar="${pillar:-"${W}/../data/configuration/pillar.sls"}"
dpillar="${W}/../pillar/init.sls"
MS_DEVMODE=""
if [ -e "$pillar" ];then cp -fv "${pillar}" "${dpillar}";fi
salt-call --retcode-passthrough -l${LEVEL} --local mc_launcher.launch "${@}"
# vim:set et sts=4 ts=4 tw=80:
