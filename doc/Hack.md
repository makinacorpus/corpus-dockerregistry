Components
------------
Shell scripts:
- a Release module in .salt to release two binaries (see: bin/release_registry.sh)

	-  one for cesanta/docker_auth (see also: bin/build-auth-binary.sh)
	-  one for the docker distribution binary (see also: bin/build-binary.sh)

Salt modules:
- mc_corpusreg.py: helpers (like password generators)
- mc_launcher.py: helper to start the circus daemon which launch all other processes:

	- nginx
	- sshd
	- cron
	- logrotate
	- registry
	- docker_auth

The image consists in
-----------------------
- an nginx reverse proxy to:

	- /docker_auth_service: cesanta/docker_auth
	- /.*: passthrough to docker registry
