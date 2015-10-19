#!/usr/bin/env bash
set -ex
salt-call --local -lall mc_project.deploy registry
# vim:set et sts=4 ts=4 tw=80:
