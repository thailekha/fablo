#!/usr/bin/env bash

get_container_id() {
  container_name=$1
  while ! docker ps -f "name=$container_name" -f "status=running" --format "{{.ID}}" | grep -q .; do
    sleep 1
  done

  container_ids=$(docker ps --filter "name=$container_name" --format "{{.ID}}")
  count=$(echo "$container_ids" | wc -l)

  if [[ $count -eq 0 ]]; then
    echo "No container with the name '$container_name' found."
    exit 1
  elif [[ $count -gt 1 ]]; then
    echo "More than one container with the name '$container_name' found."
    exit 1
  else
    echo -n "$container_ids"
  fi
}
