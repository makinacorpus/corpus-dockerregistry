#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import time
import salt.loader


PROJECT = 'registry'


def reconfigure(name=PROJECT):
    '''
    Run everything here that needed to reconf
    your app based on discovery or new pillar
    configuration upon a container boot.
    '''
    _s = __salt__
    cfg = _s['mc_project.get_configuration'](name)
    ret = _s['mc_project.deploy'](name,
                                  only='install',
                                  only_steps=['050_conf.sls'])
    output = salt.loader.outputters(__opts__)
    print(output['nested'](ret))
    if not ret['result']:
        raise ValueError('configure failed')
    return ret


def launch(name=PROJECT, re_configure=False):
    '''
    Run what's needed and stop everything

    This means for example launching circus
    and stopping it and all that it can have left
    behind
    '''
    if re_configure:
        reconfigure(name=name)
    # this will block here, we launch circus, if this die
    # it means that the app died somehow
    ret = {'retcode': 1}
    start = time.time()
    try:
        print('Circus is starting <C-C> to stop')
        ret = __salt__['cmd.run_all']('/usr/bin/circus.sh start')
    except (KeyboardInterrupt, IOError, OSError) as exc:
        # try to shutdown circus if possible
        now = time.time()
        print('graceful circus stop')
        for i in range(30):
            print('Circus stop try {0}/30'.format(i))
            time.sleep(0.04)
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
            time.sleep(0.04)
            cret = __salt__['cmd.run_all']('circusctl quit --waiting')
            for out in ['stdout', 'stderr']:
                if 'already' in cret[out]:
                    cret['retcode'] = 1
            if time.time() > (now + 10):
                print('Failed to stop')
                break
            if not cret['retcode']:
                break
        # try to remove leftover processes
        for i in ['cron', 'nginx', 'sshd', 'rsyslogd', 'fail2ban-server']:
            __salt__['cmd.run_all']('killall -9 {0}'.format(i))
        # try to remove leftover processes for this particular image
        for i in ['redis-server']:
            __salt__['cmd.run_all']('killall -9 {0}'.format(i))
    if ret['retcode'] != 0:
        raise Exception('died')
# vim:set et sts=4 ts=4 tw=80:
