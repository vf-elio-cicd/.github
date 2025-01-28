#!/usr/bin/env bash

CWD=$(pwd)
SECRETS_TYPE=${SECRETS_TYPE:-enc}
SELECTED_FILES+=($(find "${CWD}" -type f \( -name "*.${SECRETS_TYPE}.yaml" -o -name "*.${SECRETS_TYPE}.yml" -o -name "*.${SECRETS_TYPE}.json" \) -print | sort -u))

echo
for work_file in "${SELECTED_FILES[@]}"; do
  current_filename=$(basename ${work_file})
  secret_dir=$(dirname "${work_file}")
  decrypted_filename="${current_filename/.${SECRETS_TYPE}./.dec.}"
  decrypted_file="${secret_dir}/${decrypted_filename}"
  sops updatekeys -y "${work_file}"
  sops -d -s "${work_file}" > "${decrypted_file}"
done
