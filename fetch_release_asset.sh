#!/bin/bash
# USAGE
# fetch_release_asset <filename> <org/repo> <version or 'latest'> [<github token>] [<target>]
set -e

if [ $# -lt 3 ] ;then
    echo "Usage: <filename> <org/repo> <version or 'latest'> [<github token>] [<target>]"
    exit 1
fi

FILE=${1:?"Missing file input in the action"}
REPO=${2:?"Missing repo input in the action"}
VERSION=${3:-'latest'}
TOKEN="${4}"
TARGET=${5:-$1}

API_URL="https://api.github.com/repos/$REPO"
RELEASE_DATA=$(curl ${TOKEN:+"-H"} ${TOKEN:+"Authorization: token ${TOKEN}"} \
                    "$API_URL/releases/${VERSION}")
MESSAGE=$(echo "$RELEASE_DATA" | jq -r ".message")

if [[ "$MESSAGE" == "Not Found" ]]; then
  echo "[!] Release asset not found"
  echo "Release data: $RELEASE_DATA"
  echo "-----"
  echo "repo: $REPO"
  echo "asset: $FILE"
  echo "target: $TARGET"
  echo "version: $VERSION"
  exit 1
fi

echo "MESSAGE: '$RELEASE_DATA'"

ASSET_ID=$(echo "$RELEASE_DATA" | jq -r ".assets | map(select(.name == \"${FILE}\"))[0].id")
TAG_VERSION=$(echo "$RELEASE_DATA" | jq -r ".tag_name" | sed -e "s/^v//" | sed -e "s/^v.//")
RELEASE_NAME=$(echo "$RELEASE_DATA" | jq -r ".name")
RELEASE_BODY=$(echo "$RELEASE_DATA" | jq -r ".body")

if [[ -z "$ASSET_ID" ]]; then
  echo "Could not find asset id"
  exit 1
fi

curl \
  -J \
  -L \
  -H "Accept: application/octet-stream" \
  ${TOKEN:+"-H"} ${TOKEN:+"Authorization: token ${TOKEN}"} \
  "$API_URL/releases/assets/$ASSET_ID" \
  --create-dirs \
  -o "${TARGET}"

echo "::set-output name=version::$TAG_VERSION"
echo "::set-output name=name::$RELEASE_NAME"
echo "::set-output name=body::$RELEASE_BODY"