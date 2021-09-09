#!/bin/sh

REDIS_IMAGE=${REDIS_IMAGE:=redis}

SERVER_IMAGE=${SERVER_IMAGE:=student-redis}
CLIENT_IMAGE=${CLIENT_IMAGE:=${REDIS_IMAGE}}

SERVER_IMAGE_ESCPAE=$(echo "$SERVER_IMAGE" | sed -e 's/[^a-zA-Z0-9_.-]/_/g')
CLIENT_IMAGE_ESCAPE=$(echo "$SERVER_IMAGE" | sed -e 's/[^a-zA-Z0-9_.-]/_/g')

RESULT_DIR=${RESULT_DIR:=out/}

echo "Server Image Name: $SERVER_IMAGE"
echo "Client Image Name: $CLIENT_IMAGE"

SERVER_NAME=test-server-$SERVER_IMAGE_ESCPAE-$CLIENT_IMAGE_ESCAPE
CLIENT_NAME=test-client-$SERVER_IMAGE_ESCPAE-$CLIENT_IMAGE_ESCAPE
NETWORK_NAME=test-network-$SERVER_IMAGE_ESCPAE-$CLIENT_IMAGE_ESCAPE


TIMEOUT="300"

install_timeout() {
    sleep $TIMEOUT && echo "TIMEOUT!!" && (
        docker rm -f $CLIENT_NAME >/dev/null 2>&1
        docker rm -f $SERVER_NAME >/dev/null 2>&1
        docker network rm $NETWORK_NAME >/dev/null 2>&1
    ) &
}

stop_timeout() {
    pkill -f -x "sleep $TIMEOUT" >/dev/null 2>&1
}

trap ctrl_c INT

ctrl_c() {
    stop_timeout
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1
    exit
}