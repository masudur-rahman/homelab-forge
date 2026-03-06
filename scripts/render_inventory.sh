#!/bin/bash
set -e

# Usage: ./render_inventory.sh [infra|compute]
ENV=$1
TF_DIR="../homelab-genesis"
ANSIBLE_INV_DIR="./inventories/${ENV}"

if [ -z "$ENV" ]; then
    echo "❌ Error: Please specify environment (infra or compute)"
    exit 1
fi

echo "bridge: 🏗️  Generating inventory for [$ENV]..."

# 1. Switch Terraform Workspace & Get Output
TF_OUTPUT=$(cd "$TF_DIR" && \
            export TF_DATA_DIR="states/.terraform" && \
            terraform workspace select "$ENV" > /dev/null && \
            terraform output -json)

# 2. Parse JSON and Format for Ansible (INI Format)
echo "$TF_OUTPUT" | jq -r '
  .nodes.value | to_entries[] |
  .key as $group |
  (
    "[" + $group + "]",
    (
      .value | to_entries[] |
      (.value | split("/")[0]) as $ip |

      "\(.key) ansible_host=\($ip) ansible_user=unknown"
    ),
    ""
  )
' > "${ANSIBLE_INV_DIR}/hosts.ini"

echo "bridge: ✅ Inventory written to ${ANSIBLE_INV_DIR}/hosts.ini"
