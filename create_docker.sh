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

docker build \
    --rm \
    --tag=php-dev-box \
    .
