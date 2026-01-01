#!/bin/bash
set -e

# Usage: ./inventory_gen.sh [infra|compute]
ENV=$1
TF_DIR="../homelab-genesis"
ANSIBLE_INV_DIR="./inventories/${ENV}"

if [ -z "$ENV" ]; then
    echo "❌ Error: Please specify environment (infra or compute)"
    exit 1
fi

echo "bridge: 🏗️  Generating inventory for [$ENV]..."

# 1. Switch Terraform Workspace & Get Output
# We force TF_DATA_DIR to point to the states/.terraform folder we defined in the Makefile
TF_OUTPUT=$(cd "$TF_DIR" && \
            export TF_DATA_DIR="states/.terraform" && \
            terraform workspace select "$ENV" > /dev/null && \
            terraform output -json)


# 2. Parse JSON and Format for Ansible (INI Format)
echo "$TF_OUTPUT" | jq -r '
  .standard_vm_ips.value | to_entries[] |
  .key as $group |
  (
    "[" + $group + "]",
    (
      .value | to_entries[] |
      .key as $i | .value as $ip |
      "\($group)-\( ($i + 1) | tostring | if length == 1 then "0" + tostring else tostring end ) ansible_host=\($ip) ansible_user=unknown"
    ),
    ""
  )
' > "${ANSIBLE_INV_DIR}/hosts.ini"

echo "bridge: ✅ Inventory written to ${ANSIBLE_INV_DIR}/hosts.ini"
