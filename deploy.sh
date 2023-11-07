#!/bin/bash

host="" # misskey.example.com 
host_ip="" # eternal IP
misskey_user="misskey"
misskey_user_uid=$(id -u "$misskey_user")
registry="docker.io"
registry_user="" # If login is required to pull images
registry_password="" # If login is required to pull images
docker_repository="docker.io/misskey:develop";

# Check if root
#if [ "$(id -u)" -ne 0 ]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi

echo "Process: update packages;";
apt update && apt upgrade -y

echo "Process: docker remove;";
sudo -iu $misskey_user docker ps -aq | xargs -r docker rm -f;

if [ -z "$registry_user" ]; then
   echo "Process: docker login: skip";
else
   echo "Process: docker login;";
   sudo -iu $misskey_user docker login $registry --username $registry_user --password $registry_password;
fi

echo "Process: docker pull;";
sudo -iu $misskey_user XDG_RUNTIME_DIR=/run/user/$misskey_user_uid DOCKER_HOST=unix:///run/user/$misskey_user_uid/docker.sock docker pull "$docker_repository";

echo "Process: docker run;";
sudo -iu $misskey_user XDG_RUNTIME_DIR=/run/user/$misskey_user_uid DOCKER_HOST=unix:///run/user/$misskey_user_uid/docker.sock docker run -d -p 3000:3000 --add-host=$host:$host_ip -v /home/$misskey_user/misskey/files:/misskey/files -v "/home/$misskey_user/misskey/.config/default.yml":/misskey/.config/default.yml:ro --restart unless-stopped -t "$docker_repository";

echo "Process: docker image prune;";
sudo -iu $misskey_user XDG_RUNTIME_DIR=/run/user/$misskey_user_uid DOCKER_HOST=unix:///run/user/$misskey_user_uid/docker.sock docker image prune -f;

echo "Process: docker logout;";
sudo -iu $misskey_user docker logout $registry;
