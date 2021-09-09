#!/bin/sh

cd "$(dirname "$0")/.." || exit

. ./scripts/common.sh


gen() {
    basename="$1"
    echo "Generating $1..."

    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1

    install_timeout

    ## Spawn server
    docker network create $NETWORK_NAME
    docker run --rm --name $SERVER_NAME --network $NETWORK_NAME -d  $REDIS_IMAGE

    ## Wait for spawning...
    sleep 1
    
    ## Run Prepare
    if test -f "${PWD}/tests/pre.in/$basename"; then
        echo "Preparing..."
        docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/pre.in:/tests:ro -v${OUT_DIR}:/out $REDIS_IMAGE bash -c "cat /tests/$basename | redis-cli --raw -h $SERVER_NAME > /dev/null"
    fi


    ## Test Server
    OUT_DIR=$(mktemp -d)
    in="/tests/$basename"
    out="/out/$basename"
    docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/in:/tests:ro -v${OUT_DIR}:/out $REDIS_IMAGE bash -c "cat $in | redis-cli --raw -h $SERVER_NAME > $out"

    cp $OUT_DIR/$basename tests/out/$basename


    ## Check Post Condition

    if test -f "${PWD}/tests/post.in/$basename"; then
        POST_OUT_DIR=$(mktemp -d)
        in="/tests/$basename"
        out="/out/$basename"
        docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/post.in:/tests:ro -v${POST_OUT_DIR}:/out $REDIS_IMAGE bash -c "cat $in | redis-cli --raw -h $SERVER_NAME > $out"
        
        cp $POST_OUT_DIR/$basename tests/post.out/$basename

        rm -rf $POST_OUT_DIR
    fi


    stop_timeout
    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1
    rm -rf $OUT_DIR

}

for in in tests/in/*.txt; do
    gen "$(basename ${in})"
done
