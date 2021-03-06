#!/bin/bash
cd int-usr-management/bss_resources
#curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
#sudo apt-get install -y nodejs
npm install
node ./node_modules/protractor/bin/webdriver-manager update


#GATEKEEPER API DEPLOYMENT
#

export DOCKER_HOST="tcp://sp.int3.sonata-nfv.eu:2375"
# MONGODB (USER_MANAGEMENT) Not implemented yet

# Clean database
# Removing
#docker rm -fv son-mongo
#sleep 5
# Starting
#docker run -d -p 27016:27016 --name son-mongo mongo
#while ! nc -z sp.int3.sonata-nfv.eu 27016; do
#  sleep 1 && echo -n .; # waiting for mongo
#done;

function wait_for_web() {
    until [ $(curl --connect-timeout 15 --max-time 15 -k -s -o /dev/null -I -w "%{http_code}" $1) -eq $2 ]; do
	sleep 2 && 	echo -n .;

	let retries="$retries+1"
	if [ $retries -eq 12 ]; then
	    echo "Timeout waiting for $2 status on $1"
	    exit 1
	fi
    done
}

# ADAPTER - GTKUSR (GATEKEEPER)
# Removing
echo Stopping and removing containers
docker stop son-gtkusr &&
docker rm -fv son-gtkusr &&
docker stop son-keycloak &&
docker rm -fv son-keycloak &&
sleep 5

echo Building new containers
docker-compose -f int-usr-management/um_resources/docker-compose_run.yml up -d

echo Waiting for son-gtkusr ...
# while ! nc -z sp.int3.sonata-nfv.eu 5600; do
while ! nc -z sp.int3.sonata-nfv.eu 5600; do
  sleep 1 && echo -n .; # waiting for gtkusr
done;
echo son-gtkusr Ready!

echo Waiting for son-gtkusr-keycloak ...
wait_for_web sp.int3.sonata-nfv.eu:5601 200
echo son-keycloak Ready!

echo Waiting for son-gtkusr public-key ...
wait_for_web sp.int3.sonata-nfv.eu:5600/api/v1/public-key 200
echo son-gtkusr is able to return public-key!

sleep 5

#echo Starting Tests

export DOCKER_HOST="unix:///var/run/docker.sock"
