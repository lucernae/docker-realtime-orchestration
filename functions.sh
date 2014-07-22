#!/bin/bash

REALTIME_USER=realtime
REALTIME_DIR=/home/realtime
REALTIME_DATA_DIR=${REALTIME_DIR}/analysis_data
SHAKE_DIR=${REALTIME_DIR}/shakemaps
WEB_DIR=${REALTIME_DIR}/web

BTSYNC_IMAGE=docker-realtime-btsync
APACHE_IMAGE=docker-realtime-apache
SFTP_IMAGE=docker-realtime-sftp
INASAFE_REALTIME_IMAGE=docker-realtime-inasafe

function kill_container {
    NAME=$1

    if docker.io ps -a | grep ${NAME} > /dev/null
    then
        echo "Killing ${NAME}"
        docker.io kill ${NAME}
        docker.io rm ${NAME}
    else
        echo "${NAME} is not running"
    fi
}

function build_apache_image {
    echo ""
    echo "Building Apache Image"
    echo "====================================="
    cd ${REALTIME_DIR}

    docker.io build -t AIFDR/${APACHE_IMAGE} git://github.com/${ORG}/${APACHE_IMAGE}.git

}


function run_apache_container {
    echo ""
    echo "Running apache container"
    echo "====================================="
    cd ${REALTIME_DIR}

    kill_container ${APACHE_IMAGE}

    if [ ! -d ${WEB_DIR} ]
    then
        mkdir -p ${WEB_DIR}
    fi

    cp web/index.html ${WEB_DIR}/
    cp -r web/resource ${WEB_DIR}/

    docker.io run --name="${APACHE_IMAGE}" \
        -v ${WEB_DIR}:/var/www \
        -p 8080:80 \
        -d -t AIFDR/${APACHE_IMAGE}
}

function build_sftp_server_image {
    echo ""
    echo "Building SFTP Server image"
    echo "====================================="

    docker.io build -t AIFDR/${SFTP_IMAGE} git://github.com/${ORG}/${SFTP_IMAGE}.git

}


function run_sftp_server_container {
    echo ""
    echo "Running SFTP Server container"
    echo "====================================="
    sudo mkdir ${REALTIME_DIR}
    sudo chown ${REALTIME_USER}.${REALTIME_USER} ${REALTIME_DIR}

    kill_container  ${SFTP_IMAGE}

    if [ ! -d ${SHAKE_DIR} ]
    then
        mkdir -p ${SHAKE_DIR}
    fi

    docker.io run --name="${SFTP_IMAGE}" \
        -v ${SHAKE_DIR}:/shakemaps \
        -p 9222:22 \
        -d -t AIFDR/${SFTP_IMAGE}
}


function build_btsync_image {
    echo ""
    echo "Building btsync image"
    echo "====================================="

    docker.io build -t AIFDR/${BTSYNC_IMAGE} git://github.com/${ORG}/${BTSYNC_IMAGE}.git
}

function run_btsync_container {
    echo ""
    echo "Running btsync container"
    echo "====================================="

    kill_container ${BTSYNC_IMAGE}

    if [ ! -d ${REALTIME_DATA_DIR} ]
    then
        mkdir -p ${REALTIME_DATA_DIR}
    fi

    docker.io run --name="${BTSYNC_IMAGE}" \
        -v ${REALTIME_DATA_DIR}:${REALTIME_DATA_DIR} \
        -p 8888:8888 \
        -p 55555:55555 \
        -d -t AIFDR/${BTSYNC_IMAGE}
}


function build_realtime_image {
    echo ""
    echo "Building InaSAFE Realtime Image"
    echo "====================================="

    docker.io build -t AIFDR/${INASAFE_REALTIME_IMAGE} git://github.com/${ORG}/${INASAFE_REALTIME_IMAGE}.git
}


function show_credentials {
    echo ""
    echo "You can copy files into SFTP container with these credentials:"
    echo "====================================="
    # Note you can run this command any time after the container
    # is started and all containers started will have these
    # same credentials so you should be able to safely destroy
    # and recreate this container
    docker.io cp docker-realtime-sftp:/credentials .
    cat credentials
    rm credentials
}
