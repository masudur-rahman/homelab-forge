# 🛠️ Project Forge Makefile

# Default Environment
env ?= infra

# --- CONSTANTS ---
INVENTORY_FILE := inventories/$(env)/hosts.ini
VAULT_PASS_FILE := .vault_pass_$(env)
ANSIBLE_FLAGS  := -i $(INVENTORY_FILE) -e @group_vars/all.yml -e @group_vars/$(env).yml -e @vault/$(env).yml --vault-password-file $(VAULT_PASS_FILE)

# gateway play needs hostvars from compute inventory (for adguard DNS rewrite sync)
GATEWAY_FLAGS := -i inventories/compute/hosts.ini $(ANSIBLE_FLAGS)

ifdef tags
	ANSIBLE_FLAGS += --tags $(tags)
	GATEWAY_FLAGS += --tags $(tags)
endif

ifdef limit
	ANSIBLE_FLAGS += --limit "$(limit)"
	GATEWAY_FLAGS += --limit "$(limit)"
endif

# --- SSH ARGUMENT HACK ---
# This allows "make ssh gateway-01" by turning the argument into a dummy target
ifeq (ssh,$(firstword $(MAKECMDGOALS)))
  SSH_HOST := $(word 2, $(MAKECMDGOALS))
  # Prevent Make from complaining that "gateway-01" is not a target
  $(eval $(SSH_HOST):;@:)
endif

.PHONY: help init inventory vpn configure_host expense_tracker monitoring ping check lint ssh vault-edit vault-view vault-encrypt vault-decrypt

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- SETUP ---

init: ## Install Galaxy collections
	@echo "📦 Installing Dependencies..."
	ansible-galaxy install -r collections/requirements.yml --force 2>/dev/null || true

inventory: ## Generate dynamic inventory
	@./scripts/render_inventory.sh $(env)

# --- VAULT MANAGEMENT ---

vault-edit: ## Edit vault secrets (Usage: make vault-edit env=compute)
	ansible-vault edit vault/$(env).yml --vault-password-file $(VAULT_PASS_FILE)

vault-view: ## View vault secrets (Usage: make vault-view env=compute)
	ansible-vault view vault/$(env).yml --vault-password-file $(VAULT_PASS_FILE)

vault-encrypt: ## Re-encrypt from decrypted file (Usage: make vault-encrypt env=compute)
	ansible-vault encrypt vault/$(env).decrypted.yml --vault-password-file $(VAULT_PASS_FILE) --output vault/$(env).yml
	@rm -f vault/$(env).decrypted.yml
	@echo "Encrypted vault/$(env).decrypted.yml -> vault/$(env).yml (decrypted file removed)"

vault-decrypt: ## Decrypt to a separate file for editing (Usage: make vault-decrypt env=compute)
	ansible-vault decrypt vault/$(env).yml --vault-password-file $(VAULT_PASS_FILE) --output vault/$(env).decrypted.yml
	@echo "Decrypted to vault/$(env).decrypted.yml (edit this file, then run make vault-encrypt)"

# --- OPERATIONAL TASKS ---

configure_host: ## Configure base system (User, SSH, etc)
	@echo "⚙️  Configuring Hosts for [$(env)]..."
	ansible-playbook playbooks/configure_host.yml $(ANSIBLE_FLAGS)

gateway: ## Deploy Gateway Stack (VPN + DNS + HA)
	@echo "🛡️  Deploying Gateway Services to [$(env)]..."
	ansible-playbook playbooks/gateway.yml $(GATEWAY_FLAGS)

ingress: ## Setup Ingress Proxy (Nginx + SSL)
	@echo "🚦 Deploying Ingress Controller..."
	ansible-playbook playbooks/ingress.yml $(ANSIBLE_FLAGS)

database:
	@echo "Deploying Database to [$(env)]..."
	ansible-playbook playbooks/database.yml $(ANSIBLE_FLAGS)

expense_tracker: ## Deploy Expense Tracker Bot
	@echo "🤖 Deploying Expense Tracker to [$(env)]..."
	ansible-playbook playbooks/expense_tracker.yml $(ANSIBLE_FLAGS)

monitoring: ## Deploy Monitoring Stack + Agents
	@echo "Deploying Monitoring to [$(env)]..."
	ansible-playbook playbooks/monitoring.yml $(ANSIBLE_FLAGS)

ping: ## Connectivity Check (Works for Talos/No-Python)
	@echo "📡 Pinging [$(env)] hosts..."
	ansible-playbook playbooks/ping.yml $(ANSIBLE_FLAGS)

ifeq (ssh,$(firstword $(MAKECMDGOALS)))
  SSH_SEARCH_TERM := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(SSH_SEARCH_TERM):;@:)
endif

ssh: ## SSH into a host (Usage: make ssh gateway-01)
	@ENV="$(env)" SEARCH_QUERY="$(SSH_SEARCH_TERM)" ./scripts/ssh_connect.sh $(ANSIBLE_FLAGS)

# --- CI / QA ---

PLAYBOOKS := $(wildcard playbooks/*.yml)

check: ## Dry-run syntax check all playbooks
	@echo "🔍 Syntax Check for [$(env)]..."
	@for pb in $(PLAYBOOKS); do \
		echo "  Checking $$pb..."; \
		ansible-playbook $$pb $(ANSIBLE_FLAGS) --syntax-check; \
	done

lint: ## Lint YAML files (Excludes collections to prevent hanging)
	@echo "🧹 Linting..."
	# 🟢 Exclude massive collection folders to fix hanging
	ansible-lint playbooks/*.yml roles/* --exclude collections --exclude .collection
