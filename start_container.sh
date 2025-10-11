#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

set +o errexit
git_user_name=`git config --global --get user.name`
set -o errexit


if [[ "$git_user_name" == "" ]]
then
    echo "I could not resolve your git global user.name. Please input it now:"
    read git_user_name
fi

mkdir -p mariadb-data

tag=`basename "$(pwd)"`

docker run \
  --rm \
  -it \
  -p 3000:3000 \
  -v /etc/localtime:/etc/localtime:ro \
  -v `pwd`/..:/home/$git_user_name/src/git \
  -v `pwd`/mariadb-data:/var/lib/mysql \
  -e MARIADB_ROOT_PASSWORD=1234 \
  -w /home/$git_user_name/src/git/$tag \
  --entrypoint /bin/bash \
  $tag

