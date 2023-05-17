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
peer=$2
channel=$3
chaincode=$4
version=$5
search_string="Name: $chaincode, Version: $version"

if [ -z "$version" ]; then
  echo "Usage: ./wait-for-chaincode.sh [cli] [peer:port] [channel] [chaincode] [version]"
  exit 1
fi

listChaincodes() {
  docker exec -e CORE_PEER_ADDRESS="$peer" "$cli" peer lifecycle chaincode querycommitted \
    --channelID "$channel" \
    --tls \
    --cafile "/var/hyperledger/cli/crypto-orderer/tlsca.root.com-cert.pem"
}

for i in $(seq 1 90); do
  echo "➜ verifying if chaincode ($chaincode/$version) is committed on $channel/$cli/$peer ($i)..."

  if listChaincodes 2>&1 | grep "$search_string"; then
    echo "✅ ok: Chaincode $chaincode/$version is ready on $channel/$cli/$peer!"
    exit 0
  else
    sleep 1
  fi
done

#timeout
echo "❌ failed: Failed to verify chaincode $chaincode/$version on $channel/$cli/$peer"
listChaincodes
exit 1
