#!/bin/bash

# Make us independent from working directory
pushd `dirname $0` > /dev/null
WORK_DIR=`pwd`
popd > /dev/null

# Prerequisites
docker --version > /dev/null 2>&1 || { echo >&2 "Docker not found. Please install it via https://docs.docker.com/install/"; exit 1; }
docker-machine --version > /dev/null 2>&1 || { echo >&2 "Docker machine not found. https://docs.docker.com/machine/install-machine/"; exit 1; }
docker-compose --version > /dev/null 2>&1 || { echo >&2 "Docker compose not found. Please install it via https://docs.docker.com/compose/install/"; exit 1; }

if [ ! -f "${WORK_DIR}/.env" ]; then
    if [ -f "${WORK_DIR}/.env.dist" ]; then
        cp "${WORK_DIR}/.env.dist" "${WORK_DIR}/.env"

        # Identification of an existing user system
        TMP_USER_ID=`id -u`
        TMP_GROUP_ID=`id -g`

        # Changes are made to the file
        sed -i 's#USER_ID=#'"USER_ID=${TMP_USER_ID}"'#g' ${WORK_DIR}/.env
        sed -i 's#GROUP_ID=#'"GROUP_ID=${TMP_GROUP_ID}"'#g' ${WORK_DIR}/.env
    else
        echo >&2 "The .env file does not exist. Project setup will not work"
        exit 1
    fi
    exit;
fi

source ${WORK_DIR}/.env

# Ensure all folders exists
mkdir -p ${PROJECT_PATH}
mkdir -p ${PROJECT_PATH}/${SYMFONY_LOG_PATH}
mkdir -p ${SYMFONY_LOG_PATH}
mkdir -p ${COMPOSER_PATH}
mkdir -p ${COMPOSER_PATH}/cache
mkdir -p ${SSH_KEY_PATH}

# Create an SSH private and public keys if we do not have it
if [ ! -f "${SSH_KEY_PATH}/id_rsa" ]; then
    ssh-keygen -b 4096 -t rsa -f ${SSH_KEY_PATH}/id_rsa -q -P ""
fi

# Create a file if it does not exist
if [ ! -f "${SSH_KEY_PATH}/known_hosts" ]
then
    touch ${SSH_KEY_PATH}/known_hosts
fi

# Ensure all folders exists
mkdir -p ${NGINX_LOG_PATH}
mkdir -p ${MYSQL_DATA_PATH}
mkdir -p ${USER_CONFIG_PATH}

# Create a file if it does not exist
touch ${USER_CONFIG_PATH}/.bash_history

docker-compose build

# Start server
echo "Starting docker containers..."
docker-compose up -d

# Documentation for end user

echo "URLs"
echo "Website: http://${PROJECT_DOMAIN}"
echo "phpMyAdmin: http://${PROJECT_DOMAIN}:8080"