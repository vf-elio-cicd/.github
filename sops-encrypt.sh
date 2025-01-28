#!/usr/bin/env bash

CWD=$(pwd)
SECRETS_TYPE=${SECRETS_TYPE:-dec}
SELECTED_FILES+=($(find "${CWD}" -type f \( -name "*.${SECRETS_TYPE}.yaml" -o -name "*.${SECRETS_TYPE}.yml" -o -name "*.${SECRETS_TYPE}.json" \) -print | sort -u))

echo
for work_file in "${SELECTED_FILES[@]}"; do
  current_filename=$(basename ${work_file})
  secret_dir=$(dirname "${work_file}")
  encrypted_filename="${current_filename/.${SECRETS_TYPE}./.enc.}"
  encrypted_file="${secret_dir}/${encrypted_filename}"
  sops -e -s "${work_file}" > "${encrypted_file}"
  sops updatekeys -y "${encrypted_file}"
done
