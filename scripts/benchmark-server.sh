#!/bin/sh

cd "$(dirname "$0")/.." || exit

. ./scripts/common.sh

mkdir -p $RESULT_DIR

benchmark() {
    echo "Testing $1..."

    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1

    install_timeout

    ## Spawn server
    docker network create $NETWORK_NAME
    docker run --rm --name $SERVER_NAME --network $NETWORK_NAME -d  $SERVER_IMAGE

    ## Wait for spawning...
    sleep 1

    ## Test Server
    OUT_DIR=$(mktemp -d)
    out="/out/$1.txt"
    docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/in:/tests:ro -v${OUT_DIR}:/out $CLIENT_IMAGE bash -c "redis-benchmark -h $SERVER_NAME $2 | tee  $out"

    cp $OUT_DIR/$1.txt $RESULT_DIR/$1.txt



    stop_timeout
    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1
    rm -rf $OUT_DIR

}

benchmark set_1 "-t set -n 1000 -r 1000"
benchmark get_1 "-t set,get -n 1000 -r 1000"