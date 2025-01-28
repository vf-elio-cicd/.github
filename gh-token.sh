#!/usr/bin/env bash

set -o pipefail

b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }

CWD=$(pwd)
DECRYPTED=$(sops -d -s "secrets/elio/sops.enc.yaml" )
PRIVATE_KEY_PATH="${CWD}/.act/pem_file.pem"

echo "${DECRYPTED}" | yq -- '.github.app_auth.pem_file' > "${PRIVATE_KEY_PATH}"

APP_ID=$(echo "${DECRYPTED}" | yq -- '.github.app_auth.id')
INSTALLATION_ID=$(echo "${DECRYPTED}" | yq -- '.github.app_auth.installation_id')

GITHUB_OWNER="${1:-$(echo "${DECRYPTED}" | yq -- '.github.owner')}"
GITHUB_REPO="${2:-$(basename $(pwd))}"
DEBUG=${3:-false}

if [[ "${GITHUB_REPO}" == "" ]];
then
  echo "You need to provide the Repository Name"
fi

if [[ "${DEBUG}" =~ "true" ]];
then
  echo "GITHUB_OWNER:     ${GITHUB_OWNER}"
  echo "GITHUB_REPO:      ${GITHUB_REPO}"
  echo "PRIVATE_KEY_PATH: ${PRIVATE_KEY_PATH}"
fi
# file path of the private key as second argument
pem=$(cat "${PRIVATE_KEY_PATH}")

now=$(date +%s)

# shellcheck disable=SC2004
iat=$((${now} - 60)) # Issues 60 seconds in the past

# shellcheck disable=SC2004
exp=$((${now} + 600)) # Expires 10 minutes in the future

header_json='{
    "typ":"JWT",
    "alg":"RS256"
}'

# Header encode
header=$(echo -n "${header_json}" | b64enc)

payload_json="{
    \"iat\":${iat},
    \"exp\":${exp},
    \"iss\":\"${APP_ID}\"
}"

payload=$(echo -n "${payload_json}" | b64enc)

header_payload="${header}"."${payload}"

signature=$(
    openssl dgst -sha256 -sign <(echo -n "${pem}") \
    <(echo -n "${header_payload}") | b64enc
)

JWT="${header_payload}"."${signature}"

APPLICATION_ACCESS_TOKEN=$(curl -s --request POST\
 --url "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens"\
 --header "Accept: application/vnd.github+json"\
 --header "Authorization: Bearer ${JWT}"\
 --header "X-GitHub-Api-Version: 2022-11-28" | jq -Sr '.token')

export GH_PAGER=""

unset GH_TOKEN
unset GITHUB_TOKEN

export GH_TOKEN=${APPLICATION_ACCESS_TOKEN}
export GITHUB_TOKEN=${APPLICATION_ACCESS_TOKEN}

echo
echo "Application Access Token:"
echo "${APPLICATION_ACCESS_TOKEN}"
echo
