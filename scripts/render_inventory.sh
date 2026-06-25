#!/bin/bash
set -euo pipefail

# Usage: ./render_inventory.sh [infra|compute]
ENV="${1:-}"
TF_DIR="../homelab-genesis"
FORGE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANSIBLE_INV_DIR="${FORGE_ROOT}/inventories/${ENV}"
GENESIS_SECRETS="${TF_DIR}/files/secrets"

if [ -z "$ENV" ]; then
    echo "❌ Error: Please specify environment (infra or compute)"
    exit 1
fi

echo "🏗️  Generating inventory for [$ENV]..."

# 1. Switch Terraform workspace & get output
TF_OUTPUT=$(cd "$TF_DIR" && \
            export TF_DATA_DIR="states/.terraform" && \
            terraform workspace select "$ENV" > /dev/null && \
            terraform output -json)

HOSTS="${ANSIBLE_INV_DIR}/hosts.ini"
mkdir -p "$ANSIBLE_INV_DIR"

# 2. Standard (Debian) nodes — SSH-managed
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
' > "$HOSTS"

# 3. Talos clusters — no SSH; managed locally via kubeconfig (delegate_to: localhost)
if echo "$TF_OUTPUT" | jq -e '(.talos_clusters.value // {}) | length > 0' > /dev/null 2>&1; then
    mkdir -p "${ANSIBLE_INV_DIR}/files"

    # 3a. One meta-host per cluster for k8s plays
    {
        echo "[k8s]"
        echo "$TF_OUTPUT" | jq -r --arg dir "${ANSIBLE_INV_DIR}/files" '
          .talos_clusters.value | to_entries[] |
          "\(.key) ansible_connection=local"
          + " kubeconfig=\($dir)/\(.key)_kubeconfig.yaml"
          + " talosconfig=\($dir)/\(.key)_talosconfig.yaml"
        '
        echo ""
    } >> "$HOSTS"

    # 3b. Individual nodes for reference/monitoring (no SSH)
    {
        echo "[talos_nodes]"
        echo "$TF_OUTPUT" | jq -r '
          .talos_clusters.value | to_entries[] | .key as $cluster |
          ( .value.node_ips | to_entries[] |
            (.value | split("/")[0]) as $ip |
            "\(.key) ansible_host=\($ip) cluster=\($cluster) ansible_connection=local"
          )
        '
        echo ""
    } >> "$HOSTS"

    # 3c. Copy kube/talos configs from genesis
    for cluster in $(echo "$TF_OUTPUT" | jq -r '.talos_clusters.value | keys[]'); do
        for kind in kubeconfig talosconfig; do
            src="${GENESIS_SECRETS}/${cluster}_${kind}.yaml"
            dst="${ANSIBLE_INV_DIR}/files/${cluster}_${kind}.yaml"
            if [ -f "$src" ]; then
                cp "$src" "$dst"
                chmod 600 "$dst"
                echo "🔑 Copied ${cluster}_${kind}.yaml"
            else
                echo "⚠️  Missing $src — run terraform apply in homelab-genesis first"
            fi
        done
    done
fi

echo "✅ Inventory written to $HOSTS"
