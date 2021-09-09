#!/bin/sh

cd "$(dirname "$0")/.." || exit


. ./scripts/common.sh

mkdir -p $RESULT_DIR


runtest() {
    basename="$1"
    printf "\e[34mTesting $1...\e[39m\n"

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

    ## Run Prepare
    if test -f "${PWD}/tests/pre.in/$basename"; then
        echo "Preparing..."
        docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/pre.in:/tests:ro -v${OUT_DIR}:/out $REDIS_IMAGE bash -c "cat /tests/$basename | redis-cli --raw -h $SERVER_NAME > /dev/null"
    fi

    ## Test Server
    OUT_DIR=$(mktemp -d)
    in="/tests/$basename"
    out="/out/$basename"
    docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/in:/tests:ro -v${OUT_DIR}:/out $CLIENT_IMAGE bash -c "cat $in | redis-cli --raw -h $SERVER_NAME > $out"

    diff -q $OUT_DIR/$basename tests/out/$basename 

    if [ $? -ne 0 ]; then
        echo "ERR (response below)\n" >$RESULT_DIR/$basename 2>&1
        cat $OUT_DIR/$basename  >>$RESULT_DIR/$basename 2>&1
        printf "Test $1 [\e[31mFAILED\e[39m]\n"
    else
        echo "OK" >$RESULT_DIR/$basename 2>&1
        printf "Test $1 [\e[32mOK\e[39m]\n"
    fi

    ## Check Post Condition

    if test -f "${PWD}/tests/post.in/$basename"; then
        POST_OUT_DIR=$(mktemp -d)
        in="/tests/$basename"
        out="/out/$basename"
        docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${PWD}/tests/post.in:/tests:ro -v${POST_OUT_DIR}:/out $REDIS_IMAGE bash -c "cat $in | redis-cli --raw -h $SERVER_NAME > $out"
        diff -q $POST_OUT_DIR/$basename tests/post.out/$basename 

        if [ $? -ne 0 ]; then
            echo "ERR (response below)\n" >$RESULT_DIR/${basename}.post 2>&1
            cat $POST_OUT_DIR/$basename  >>$RESULT_DIR/${basename}.post 2>&1
            printf "Test $1 (postcondition) [\e[31mFAILED\e[39m]\n"
        else
            echo "OK" >$RESULT_DIR/${basename}.post 2>&1
            printf "Test $1 (postcondition) [\e[32mOK\e[39m]\n"
        fi

        rm -rf $POST_OUT_DIR
    fi




    stop_timeout
    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1
    rm -rf $OUT_DIR

}


runtest_large() {
    printf "\e[34mTesting Large Binary $1...\e[39m\n"

    ## Cleanup
    docker rm -f $CLIENT_NAME >/dev/null 2>&1
    docker rm -f $SERVER_NAME >/dev/null 2>&1
    docker network rm $NETWORK_NAME >/dev/null 2>&1

    ## Creating test vector
    TEST_DIR=$(mktemp -d)
    IN_DIR=$(mktemp -d)
    docker run --rm --name $CLIENT_NAME -v${TEST_DIR}:/out $REDIS_IMAGE bash -c "head -c $1 /dev/urandom > /out/test.bin"
    docker run --rm --name $CLIENT_NAME -v${IN_DIR}:/out $REDIS_IMAGE bash -c "printf \"get foo\" > /out/get.txt"

    install_timeout

    ## Spawn server
    docker network create $NETWORK_NAME
    docker run --rm --name $SERVER_NAME --network $NETWORK_NAME -d  $SERVER_IMAGE

    ## Wait for spawning...
    sleep 3

    OUT_DIR=$(mktemp -d)
    docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${TEST_DIR}:/tests:ro $REDIS_IMAGE bash -c "redis-cli --raw -h $SERVER_NAME  -x set foo < /tests/test.bin"
    docker run --rm --name $CLIENT_NAME --network $NETWORK_NAME -v${IN_DIR}:/in:ro -v${OUT_DIR}:/out $CLIENT_IMAGE bash -c "cat /in/get.txt | redis-cli --raw -h $SERVER_NAME | sed -z '$ s/\n$//'  > /out/result.bin"

    diff  $TEST_DIR/test.bin $OUT_DIR/result.bin

    if [ $? -ne 0 ]; then
        echo "ERR" >$RESULT_DIR/large-$1.txt 2>&1
        printf "Test $1 [\e[31mFAILED\e[39m]\n"
    else
        echo "OK" >$RESULT_DIR/large-$1.txt 2>&1
        printf "Test $1 [\e[32mOK\e[39m]\n"
    fi
    
    stop_timeout

    rm -rf $TEST_DIR $OUT_DIR $IN_DIR
}



for in in tests/in/*.txt; do
    runtest "$(basename ${in})"
done

runtest_large 1K
runtest_large 4K
runtest_large 2M
runtest_large 128M
runtest_large 512M