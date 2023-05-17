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

cli="$(get_container_id $1)"
peer="$2"
channel="$3"
chaincode="$4"
command="$5"
expected="$6"
transient_default="{}"
transient="${7:-$transient_default}"

if [ -z "$expected" ]; then
  echo "Usage: ./expect-invoke.sh [cli] [peer:port[,peer:port]] [channel] [chaincode] [command] [expected_substring] [transient_data]"
  exit 1
fi

label="Invoke $channel/$cli/$peer $command"
echo ""
echo "➜ testing: $label"

peerAddresses="--peerAddresses $(echo "$peer" | sed 's/,/ --peerAddresses /g')"

response="$(
  # shellcheck disable=SC2086
  docker exec "$cli" peer chaincode invoke \
    $peerAddresses \
    -C "$channel" \
    -n "$chaincode" \
    -c "$command" \
    --transient "$transient" \
    --waitForEvent \
    --waitForEventTimeout 90s \
    2>&1
)"

echo "$response"

if echo "$response" | grep -F "$expected"; then
  echo "✅ ok (cli): $label"
else
  echo "❌ failed (cli): $label | expected: $expected"
  exit 1
fi
