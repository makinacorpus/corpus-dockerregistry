#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import time
import salt.loader


PROJECT = 'registry'


def reconfigure(name=PROJECT):
    ret = __salt__['mc_project.deploy'](name, only='install', only_steps=['050_conf.sls'])
    output = salt.loader.outputters(__opts__)
    print(output['nested'](ret))
    if not ret['result']:
        raise ValueError('configure failed')
    return ret


def launch(name=PROJECT, regreconfigure=False):
    if reconfigure:
        reconfigure(name=name)
    # this will block here, we launch circus, if this die
    # it means that the app died somehow
    print('Circus is starting <C-C> to stop')
    ret = {'retcode': 1}
    start = time.time()
    try:
        ret = __salt__['cmd.run_all']('/usr/bin/circus.sh start', python_shell=True)
    except (KeyboardInterrupt, IOError, OSError) as exc:
        # try to shutdown circus if possible
        now = time.time()
        __salt__['cmd.run_all']('killall -9 cron')
        __salt__['cmd.run_all']('killall -9 nginx')
        print('graceful circus stop')
        for i in range(30):
            print('Circus stop try {0}/30'.format(i))
            time.sleep(1)
            cret = __salt__['cmd.run_all']('circusctl stop')
            for out in ['stdout', 'stderr']:
                if 'already' in cret[out]:
                    cret['retcode'] = 1
            if time.time() > (now + 10):
                print('Failed to stop')
                break
            if not cret['retcode']:
                break
        print('graceful circus quit')
        for i in range(30):
            print('Circus shutdown try {0}/30'.format(i))
            time.sleep(1)
            cret = __salt__['cmd.run_all']('circusctl quit --waiting')
            for out in ['stdout', 'stderr']:
                if 'already' in cret[out]:
                    cret['retcode'] = 1
            if time.time() > (now + 10):
                print('Failed to stop')
                break
            if not cret['retcode']:
                break
    if ret['retcode'] != 0:
        raise Exception('died')
# vim:set et sts=4 ts=4 tw=80:
