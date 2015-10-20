Makina-States bases docker registry
===================================
This provides a docker distribution (registry v2) docker image based on makina-states.<br/>
This registry embeds a daemon that implements registry V2 tokens, (cesanta/docker_auth).<br/>
The registry won't allow any anonymous configuration.

Code organization
-------------------
We separate the project codebase from any persistent daa that it needs and create.<br/>
For this we use two root separates folders, one for the clone, and one for the persistent data.<br/>
By convention, the name of the persistant data holding directory is the name of the clone folder suffixed by "_data".<br/>
Eg if you clone your project inside "/project", the data folder will be /project_data".<br/>
The data folder can't et must not be inside the project folder as we drastically play with unix permissions to ensure proper security and the two of those folders do not have the same policies.

Volumes
-----------
You need to add a volume that will contains those subdirs::
<pre>

project/            <- git clone of this repository, the project code inside the
                       container. this folder contains a '.salt' folder which 
                       describe how to install & configure this project.
                       (/srv/projects/<name>/project)
project_data/da     <- ssl generated certificates
project_data/volume <- mounted as the persistent data folder inside the container
                       (/srv/projects/<name>/data)
</pre>

***project_data***
<pre>
project_data/volume/configuration: <- contains the configuration
  pillar.sls:        <- extra registry saltstack configuration
  registry.webaccess <- htpasswd file               (created but empty)
project_data/volume/data/images    <- where the images are stored (autocreated)
project_data/volume/data/www_dir   <- reverse proxy docroot       (autocreated)

</pre>


Download and initialise the layout
--------------------------------------
<pre>
cd $WORKSPACE <- whereever you want to clone the project
git clone https://github.com/makinacorpus/corpus-dockerregistry.git project
mkdir project_data
</pre>

OPTIONAL: Generate a a certificate with a custom authority for test
----------------------------------------------------------------------------
<pre>
cd $WORKSPACE/project_data
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
</pre>

Register the certificate to the local openssl configuration
<pre>
cp ca/${domain}.bundle.crt /usr/local/share/ca-certificates && update-ca-certificates
</pre>

Configure the PILLAR
-------------------------
You need then to fill the pillar to setup a domain to serve for the registry (the virtualhost name) and the SSL certificate details
<pre>
cd $WORKSPACE/project_data
mkdir -p configuration
cp .salt/PILLAR.sample volume/configuration/pillar.sls
sed -re "s/makina-projects.projectname/makina-projects.registry/g" -i volume/configuration/pillar.sls
$EDITOR volume/configuration/pillar.sls
  -> edit at least:

    - domain
    - certificate key and bundle (content) 
      (maybe cat project_data/ca/ca/${domain}.bundle.crt
       && cat ca/${domain}.${domain}-key.pem
    - list of http users and password to allow
    - You can remove what is not overriden if you want.
</pre>

Example configuration/pillar.sls
<pre>
makina-projects.registry:
  data:
    domain: "registryh.docker.tld"
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
    ssl_key: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpQIBAAKCAQEAzzBVPJvbMXFBN1mErd+T3QDUpvI6YvJt3JJjBptvcke1X9Si
      ...
      fFwSDE8arfpgbAfrtYgWjd0248GRV46iE1BuE4uuZ41XQ9J9DILzjMk=
      -----END RSA PRIVATE KEY-----
</pre>


Allow users to connect to the registry
--------------------------------------

Build & Run
-------------
You do not need to Build the image, you can directly download it from the docker-hub.
<pre>
docker build -t makinacorpus/registry .
# or docker pull makinacorpus/registry
</pre>
Run
<pre>
docker run -d -v "${PWD}_data/volume":/srv/projects/registry/data makinacorpus/registry
</pre>

Hack the code of this repository
---------------------------------

