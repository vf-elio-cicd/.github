#!/usr/bin/env bash

set -eou pipefail

source "gh-token.sh"

gh --repo "vf-elio-cicd/$(basename $(pwd))" variable set -f ./.act/.vars
gh --repo "vf-elio-cicd/$(basename $(pwd))" secret set -f ./.act/.secrets
