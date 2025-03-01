#!/bin/sh -e

for folder in $(cat /opt/diun/watch.txt); do
    if [ ! -f "$folder/.env" ]; then
        continue
    fi

    image_name=$(grep '^IMAGE=' "$folder/.env" | cut -d'=' -f2 | cut -d':' -f1)

    if [ -z "$image_name" ] || ! echo "${DIUN_ENTRY_IMAGE}" | grep -q "$image_name"; then
        continue
    fi

    docker pull ${DIUN_ENTRY_IMAGE}

    docker compose -f $folder/docker-compose.yml down --rmi all

    sed -i "s|^\(IMAGE=\).*|\1${DIUN_ENTRY_IMAGE}|" $folder/.env

    docker compose -f $folder/docker-compose.yml up -d

    break
done
