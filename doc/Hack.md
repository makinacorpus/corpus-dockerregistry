Hacking notes
================
Develop the code of this image without rebuilding everytime
------------------------------------------------------------
To allow file cooperation from inside/out or the container, we use a special editor group that has access to the most important files of your container.

Those files are shared via a docker volumes.

This allows you to:

    - develop from outside the container
    - do any git operation from outside

The editor group must exists on your local machine, and if **editor** already exists, just choose another name. The important thing is to share the **gid** (65753).
```bash
sudo groupadd -u 65753 editor
sudo gpasswd -a $(whoami) editor
```
Secondly, when you know that the build of your image is somewaht stable, you can tag it to speed up future container spawns.<br/>
This will speed up incremental development.<br/>
The idea is to build one the image, and then go into the container via a shell a do thinkgs manually until you are happy of the result.<br/>
You can then commit back you changes to your repo and rebuild from scratch your image without having to rebuild each time you change a single letter.<br/>

```bash
sudo docker build -t mydevtag .
```

Last but not least, now you can launch a container based on this image to hapilly hack the image
```bash
```

Specific notes for this image
------------------------------
Components
+++++++++++
Shell scripts:
- a Release module in .salt to release two binaries (see: bin/release_registry.sh)
	-  one for cesanta/docker_auth (see also: bin/build-auth-binary.sh)
	-  one for the docker distribution binary (see also: bin/build-binary.sh)

Salt modules:
- mc_corpusreg.py: helper to release the two go binaries (registry & docker_auth)
- mc_launcher.py: helper to start the circus daemon which launch all other processes:
    - nginx reverse proxy to:
        - /docker_auth_service: cesanta/docker_auth
        - /.*: passthrough to docker registry
	- sshd
	- cron
	- logrotate
	- registry
	- docker_auth

Release the go binaries
+++++++++++++++++++++++
- Maybe udpate .salt/PILLAR.sample to upgrade/edit the versions of the registry & docker_auth
- launch the release helper which will spawn a docker container, build the binaries into two others and finally upon completness upload binaries to github.
```bash
$EDITOR .salt/PILLAR.sample
export GH_USER="<github_username>"
# notice the initial space to avoid this going into your bash history
 export GH_PASSWORD="<github_password>"
./bin/release_registry.sh
```
