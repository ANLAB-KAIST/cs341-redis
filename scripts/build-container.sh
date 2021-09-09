#!/bin/sh

echo "Building ${1:-src} ..."

cd "$(dirname "$0")/.." || exit

SERVER_IMAGE=${SERVER_IMAGE:=student-redis}

docker build -t $SERVER_IMAGE ${1:-src}