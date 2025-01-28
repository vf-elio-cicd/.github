#!/usr/bin/env bash

set -euo pipefail

source gh-token.sh

PAYLOAD=payload.json

echo '{"event_type":"CI","client_payload":{}}' | jq -Sr '.' > ${PAYLOAD}

cat ${PAYLOAD}
set -x
curl \
 -vvv\
 -w '%{http_code}'\
 -X POST\
 -H "Accept: application/vnd.github+json"\
 -H "Authorization: Bearer ${GH_TOKEN}"\
 -H "X-GitHub-Api-Version: 2022-11-28"\
 -d @"${PAYLOAD}"\
 "https://api.github.com/repos/vf-elio-cicd/.github-private/dispatches"
set +x
