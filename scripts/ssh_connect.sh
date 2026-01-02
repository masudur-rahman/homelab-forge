#!/bin/bash

# Usage: ENV=infra SEARCH_QUERY="gateway" ./ssh_connect.sh <ANSIBLE_FLAGS...>

# --- Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

# Dependency Checks
if ! command -v fzf > /dev/null 2>&1; then
  echo -e "${RED}Error: 'fzf' is not installed.${NC}"
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo -e "${RED}Error: 'jq' is not installed.${NC}"
  exit 1
fi

# Fetch Inventory
# We use "$@" directly, which contains the ansible flags (-i ...) passed from Makefile
echo -e "${CYAN}🔍 Scanning inventory for [${BOLD}${ENV}${NORMAL}${CYAN}]...${NC}"
INVENTORY_JSON=$(ansible-inventory "$@" --list)

# Check if inventory was actually parsed (detects the warning)
if echo "$INVENTORY_JSON" | grep -q "No inventory was parsed"; then
    echo -e "${RED}❌ Fatal: Ansible could not parse the inventory.${NC}"
    echo -e "${YELLOW}   Command run: ansible-inventory $@${NC}"
    exit 1
fi

# Interactive Selection (fzf)
# We pipe the keys to fzf with the optional query
SELECTED_HOST=$(echo "$INVENTORY_JSON" | \
  jq -r '._meta.hostvars | keys[]' | \
  sort | \
  fzf --query "$SEARCH_QUERY" --select-1 --exit-0 \
      --prompt="🔌 SSH > " --height=40% --layout=reverse --border)

# Process Selection
if [[ -n "$SELECTED_HOST" ]]; then

  HOST_IP=$(echo "$INVENTORY_JSON" | jq -r "._meta.hostvars.\"${SELECTED_HOST}\".ansible_host")
  HOST_USER=$(echo "$INVENTORY_JSON" | jq -r "._meta.hostvars.\"${SELECTED_HOST}\".ansible_user")

  # Defaults
  if [[ "$HOST_IP" == "null" || "$HOST_IP" == "" ]]; then HOST_IP="$SELECTED_HOST"; fi
  if [[ "$HOST_USER" == "null" ]]; then HOST_USER="root"; fi

  # Key Path: keys/ssh/id_rsa_<env>
  KEY_PATH="./keys/ssh/id_rsa_${ENV}"

  echo -e "${GREEN}🎯 Target: ${BOLD}${HOST_USER}@${HOST_IP}${NORMAL}${NC}"

  CMD_ARGS=("-o" "StrictHostKeyChecking=no")

  if [[ -f "$KEY_PATH" ]]; then
    echo -e "${YELLOW}🔑 Using Key: ${KEY_PATH}${NC}"
    CMD_ARGS+=("-i" "$KEY_PATH")
  fi

  # Execute SSH
  ssh "${CMD_ARGS[@]}" "${HOST_USER}@${HOST_IP}"

else
  # Graceful exit if cancelled or no match
  if [[ -n "$SEARCH_QUERY" ]]; then
     echo -e "${YELLOW}=> 😒 No hosts found matching '${SEARCH_QUERY}'${NC}"
  else
     echo -e "${YELLOW}=> 😒 Selection cancelled${NC}"
  fi
fi
