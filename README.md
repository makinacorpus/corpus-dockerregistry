# Makina-States bases docker registry

This provides a docker distribution (registry v2) docker image based on makina-states.<br/>
This registry embeds a daemon that implements registry V2 tokens, (cesanta/docker_auth).<br/>
The registry won't allow any anonymous configuration.

You will certainly need to read the official documentation around the docker registry.<br/>
Pay attention that you need to access your registry with a DNS name and a valid SSL certificate.<br/>
This certicate must be signed by an authority (even if you generates this authority).<br/>
Other setup will make you go in troubles.<br/>
You can of course follow the SSL certificate generation snippet bellow.

## Code organization
We separate the project codebase from any persistent data that is needed to be created along any container.<br/>
For this we use two root separates folders:
 - one for the clone of the codebase: ***${PROJECT}***
 - and one for the persistent data: ***${DATA}***

By convention, the name of the persistant data holding directory is the name of the clone folder suffixed by "_data".<br/>
Eg if you clone your project inside "/project", the data folder will be /project_data".<br/>
The data folder can't et must not be inside the project folder as we drastically play with unix permissions to ensure proper security and the two of those folders do not have the same policies.<br/>
The special folder ***project_data/volume*** is mounted as a docker voume inside the container at the project data directory location. We refer it as ***${VOLUME}***.


## Filesystem Layout
You need to add a volume that will contains those subdirs::
<pre>
${PROJECT}/      <- git clone of this repository, the project code inside the
                  container. this folder contains a '.salt' folder which
                  describe how to install & configure this project.
                       (/srv/projects/<name>/project)
${DATA}/volume/ <- mounted as the persistent data folder inside the container
                 (/srv/projects/<name>/data), Alias ${VOLUME}
# specific to this image:
${DATA}/ca            <- any ssl generated certificates
${DATA}/go            <- if binary are built: build results
${DATA}/docker-auth   <- if binary are built: cesenta/docker-auth codebase
${DATA}/registry      <- if binary are built: registry codebase
</pre>

For the data, we differentiate in term of permissions the configuration from
the datas (later is more laxist).
For the configuration directories, after the image has been launched, you ll
certainly need to gain root privileges to redit any files in those subdirs.

***project_data: configuration***
<pre>
${VOLUME}/ssh/*.pub:     <- ssh public keys to allow to connect as root
${VOLUME}/configuration: <- contains the configuration
             |- pillar.sls:    <- configuration file (saltstack pillar) from the image
</pre>

***project_data: data***
<pre>
${VOLUME}/data/    <- top data dir
</pre>

Specific to this image:
<pre>
${VOLUME}/data/images    <- where the images are stored (autocreated)
${VOLUME}/data/www_dir   <- reverse proxy docroot       (autocreated)
</pre>


## Download and initialise the layout
```bash
export PROJECT="${WORKSPACE}/myproject" # where you want to put the code
export DATA="${PROJECT}_data"           # where you want to put the data
export VOLUME="${DATA}/volume"          # where you want to put the docker volume
mkdir -p "${DATA}" "${VOLUME}"
git clone https://github.com/makinacorpus/corpus-dockerregistry.git "${PROJECT}"
```

### OPTIONNAL: Generate a a certificate with a custom authority for test purposes
```bash
cd "${DATA}"
domain="yourdomain.tld"
mkdir -p ca
openssl genrsa -des3 -out ca/sca-key.pem
openssl genrsa -des3 -out ca/s${domain}-key.pem
openssl rsa -in ca/sca-key.pem -out ca/ca-key.pem
openssl rsa -in ca/s${domain}-key.pem -out ca/${domain}-key.pem
openssl req -new -x509 -days $((365*30)) -key ca/ca-key.pem -out ca/ca.pem\
  -subj "/C=FR/ST=dockerca/L=dockerca/O=dockerca/CN=dockerca/"
openssl req -new -key ca/${domain}-key.pem -out ca/${domain}.csr\
  -subj "/C=FR/ST=dockerca/L=dockerca/O=dockerca/CN=*.${domain}/"
openssl x509 -CAcreateserial -req -days $((365*30)) -in ca/${domain}.csr\
  -CA ca/ca.pem -CAkey ca-key.pem -out ca/${domain}.crt
cat ca/${domain}.crt ca.pem > ca/${domain}.bundle.crt
```

Register the certificate to the local openssl configuration
```bash
cd "${DATA}"
sudo cp ca/${domain}.bundle.crt /usr/local/share/ca-certificates && sudo update-ca-certificates
```

## Configure the image via the salt PILLAR
You need then to fill the pillar to:
  - setup a domain to serve for the registry (the virtualhost name)
  - the SSL certificate informations
  - The users ACLS for the registry, see [official doc](https://github.com/cesanta/docker_auth/blob/master/examples/reference.yml)

```bash
mkdir -p "${VOLUME}/configuration"
cp .salt/PILLAR.sample "${VOLUME}/configuration/pillar.sls"
sed -re "s/makina-projects.projectname/makina-projects.registry/g"\
  -i "${VOLUME}/configuration/pillar.sls"
$EDITOR "${VOLUME}/configuration/pillar.sls" # Adapt to your needs
```

Edit at least:
  - domain
  - certificate key and bundle (content)
    (maybe cat project_data/ca/ca/${domain}.bundle.crt
     && cat ca/${domain}.${domain}-key.pem
  - list of http users and password to allow
  - You can remove what is not overriden if you want.

Example configuration/pillar.sls
```yaml
makina-projects.registry:
  data:
    users:
      admin:
        password: test1
      readonly:
        password: test2 
    acl:
      # Admin has full access to everything.
      - {match: {account: "admin"}, actions: ["*"]}
      # User "readonly" can pull stuff.
      - {match: {account: "readonly"}, actions: ["pull"]}
      # Access is denied by default.
    # the domain serving your registry
    domain: "registryh.docker.tld"
    # the SSL certicate(incuding the intermediaries)
    ssl_cert: |
        -----BEGIN CERTIFICATE-----
        MIIDMjCCAhoCCQDvVm1SttCzxTANBgkqhkiG9w0BAQsFADBZMQswCQYDVQQGEwJG
        ...
        ugItmnXoVCkHHrZvydXC/zxah21lfVtA05xB8zsieLyLmsy8lH2exftnpM3QgMAp
        G9S8ZWex
        -----END CERTIFICATE-----
        -----BEGIN CERTIFICATE-----
        MIIDhTCCAm2gAwIBAgIJAKWNQ8MgC28RMA0GCSqGSIb3DQEBCwUAMFkxCzAJBgNV
        ...
        S17wzmffRktued3rJ+efBUvegdnbJG1nxT51znLy5mlLAD37OCf2DgqlGyL1UcEr
        XhidyUpZcJ4Fr2koosQZ8z20j2tXDanhbSi1osJ6yQi8rjRdJZeCMwA=
        -----END CERTIFICATE-----
    # the relevant SSL key
    ssl_key: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpQIBAAKCAQEAzzBVPJvbMXFBN1mErd+T3QDUpvI6YvJt3JJjBptvcke1X9Si
      ...
      fFwSDE8arfpgbAfrtYgWjd0248GRV46iE1BuE4uuZ41XQ9J9DILzjMk=
      -----END RSA PRIVATE KEY-----
```



## Allow users to connect to the registry via ssh

## Build & Run
***Be sure to have completed the initial configuration (SSL, PILLAR) before launching the container.***
You may not need to **build** the image, you can directly download it from the docker-hub.
```bash
docker pull makinacorpus/registry
# or docker build -t makinacorpus/registry .
```
Run
```bash
docker run -ti\
  -v "${PWD}_data/volume":/srv/projects/registry/data\
  makinacorpus/registry
```

## DNS configuration
When your registry container is running and you want to access it locally, in development mode,<br/>
just inspect and register it in your /etc/hosts file
```bash
IP=$(sudo docker inspect -f '{{ .NetworkSettings.IPAddress }}' <YOUR_CONTAINER_ID>)
cat | sudo sh << EOF
sed -i -re "/registryh.docker.tld/d" /etc/hosts
echo $IP registryh.docker.tld>>/etc/hosts
EOF
``` 

## Hack this image
See:
- [doc/Hack.md](doc/Hack.md)
- [doc/Registry.md](doc/Registry.md)



