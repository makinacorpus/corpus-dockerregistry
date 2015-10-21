Hacking notes
================
## Develop the code of this image without rebuilding everytime
To allow file cooperation from inside/out or the container, we use a special editor group that has access to the most important files of your container.

Those files are shared via a docker volumes.

This allows you to:
 * develop from outside the container, use your IDE, etc.
 * do any git operation from outside

### The editor group
The editor group must exists on your local machine, and if **editor** already exists, just choose another name.<br/>
The important thing is to share the **gid** (65753).
```bash
sudo groupadd -u 65753 editor
sudo gpasswd -a $(whoami) editor
```

### Building the image
The main thing you want to do with a docker image is to build it.<br/>
When you feels the build enoughtly stable, you can tag it to speed up future container spawns.<br/>
This will allows you to hack your code without having to rebuild each time you change a single letter.<br/>
```bash
sudo docker build -t mydevtag .
```
### Debugging your container, AKA live edit
#### Method 1: Manual edit (recommended)
Indeed the idea is to build one the image, and then go into the container<br/>
via a shell to do daily thinkgs manually until you are happy of the result and ready for a new build.<br/>
```bash
cat Dockerfile # see what's the hell how the image is constructed
docker run -ti mydevtag bash
# do something that's needed to make your code deployment procedure happy
# from the "mydevtag" checkpoint
# in makina-states, this is trivial
salt-call --local -lall mc_project.deploy yourproject
# The next command is supposed to launch manually your app
/srv/projects/*/bin/launch.sh
# you can then stop it and hack again and again
# Wash, Since, Repeat, Enjoy
```
***NOTE***: the "salt-call" dance is only needed when you changed something to the deployment, you may not have to run it.

#### Method 2: Edit a running container
This is mostly to inspect the running processes and stuff, but you won't be able to kill circus<br/>
as this would kill your container away.

### commiting the result back
***FROM WITHIN THE HOST***

When you have finished your work, it's time to test a final rebuild<br/>
```bash
sudo docker build -t myfinaltag .
```

And eventually, you certainly want to commit back the changes to your code repository from within your host
```bash
# git st && git add . .salt && git commit -am "Finished work" && git push
```

## Specific notes for this image
### Components
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

### Release the go binaries
- Maybe udpate .salt/PILLAR.sample to upgrade/edit the versions of the registry & docker_auth
- launch the release helper which will spawn a docker container, build the binaries into two others and finally upon completness upload binaries to github.
```bash
$EDITOR .salt/PILLAR.sample
export GH_USER="<github_username>"
# notice the initial space to avoid this going into your bash history
 export GH_PASSWORD="<github_password>"
./bin/release_registry.sh
```
