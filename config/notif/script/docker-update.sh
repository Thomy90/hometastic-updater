#!/bin/sh -e

new_image=${DIUN_ENTRY_IMAGE}
new_tag=${new_image##*:}

# Normalize image path for matching running container
normalized_image_path=${new_image#docker.io/}
normalized_image_path=${normalized_image_path#library/}
normalized_image_path=${normalized_image_path%%:*}

working_dir=$(docker ps \
  --format '{{.Image}}|{{.Label "com.docker.compose.project.working_dir"}}' \
  | awk -F'|' -v img="$normalized_image_path" '$1 ~ "^" img ":" {print $2; exit}')

if [ -z "$working_dir" ]; then
  echo "No running container found for $normalized_image_path"
  exit 1
fi

echo "Updating ${new_image} in ${working_dir}"

docker pull --quiet "${new_image}"

docker compose -f "${working_dir}/docker-compose.yml" down --rmi all

# Update .env if exists
env_file="${working_dir}/.env"

if [ -f "$env_file" ]; then
  sed -i "s|^\(IMAGE_TAG=\).*|\1${new_tag}|" "${env_file}"
  sed -i "s|^\(IMAGE=\).*|\1${new_image}|" "${env_file}"
fi

docker compose -f "${working_dir}/docker-compose.yml" up -d

echo "Update complete: ${new_image} deployed in ${working_dir}"
