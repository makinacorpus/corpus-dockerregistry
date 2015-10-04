#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function


PROJECT = 'registry'


def reconfigure(name=PROJECT):
    __salt__['mc_project.deploy'](only='install', only_steps=['050_conf.sls'])


def launch(name=PROJECT, regreconfigure=False):
    if reconfigure:
        reconfigure(name=name)
    # this will block here, we launch circus, if this die
    # it means that the app died somehow
    ret = __salt__['cmd.retcode']('/usr/bin/circus.sh start', use_vt=True)
    if ret['retcode'] != 0:
        raise Exception('died')
# vim:set et sts=4 ts=4 tw=80:
