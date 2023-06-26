#!/bin/bash

# handle control-c to stop the whole script rather than just current command
function control_c {
    exit 1
}
trap control_c SIGINT

if ! command -v docker &>/dev/null; then
    >&2 echo "Docker is not installed"
    exit 1
fi

if ! groups | grep '\bdocker\b' --only-matching &>/dev/null ; then 
    >&2 echo "Current user is not member of docker group"
    exit 2
fi


docker buildx use builder || docker buildx create --name builder --bootstrap --use

docker buildx build \
    --push \
    --rm \
    --platform linux/arm64/v8,linux/amd64 \
    --tag allansimon/docker-devbox-php \
    .
