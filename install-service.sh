#!/bin/bash -e

(
    cd "$(dirname "$0")"

    DIUN_ROOT=$(pwd) envsubst < diun.service.template | sudo tee /etc/systemd/system/diun.service > /dev/null
)

