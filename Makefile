# 🛠️ Project Forge Makefile

# Default Environment
ENV ?= infra

# --- CONSTANTS ---
INVENTORY_FILE := inventories/$(ENV)/hosts.ini
ANSIBLE_FLAGS  := -i $(INVENTORY_FILE) -e @group_vars/all.yml -e @group_vars/$(ENV).yml

ifdef tags
	ANSIBLE_FLAGS += --tags $(tags)
endif

ifdef limit
	ANSIBLE_FLAGS += --limit "$(limit)"
endif

# --- SSH ARGUMENT HACK ---
# This allows "make ssh gateway-01" by turning the argument into a dummy target
ifeq (ssh,$(firstword $(MAKECMDGOALS)))
  SSH_HOST := $(word 2, $(MAKECMDGOALS))
  # Prevent Make from complaining that "gateway-01" is not a target
  $(eval $(SSH_HOST):;@:)
endif

.PHONY: help init inventory vpn configure_host expense_tracker ping check lint ssh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- SETUP ---

init: ## Install Galaxy collections
	@echo "📦 Installing Dependencies..."
	ansible-galaxy install -r collections/requirements.yml --force 2>/dev/null || true

inventory: ## Generate dynamic inventory
	@./scripts/render_inventory.sh $(ENV)

# --- OPERATIONAL TASKS ---

configure_host: ## Configure base system (User, SSH, etc)
	@echo "⚙️  Configuring Hosts for [$(ENV)]..."
	ansible-playbook playbooks/configure_host.yml $(ANSIBLE_FLAGS)

gateway: ## Deploy Gateway Stack (VPN + DNS + HA)
	@echo "🛡️  Deploying Gateway Services to [$(ENV)]..."
	ansible-playbook playbooks/gateway.yml $(ANSIBLE_FLAGS)

ingress: ## Setup Ingress Proxy (Nginx + SSL)
	@echo "🚦 Deploying Ingress Controller..."
	ansible-playbook playbooks/ingress.yml $(ANSIBLE_FLAGS)

expense_tracker: ## Deploy Expense Tracker Bot
	@echo "🤖 Deploying Expense Tracker to [$(ENV)]..."
	ansible-playbook playbooks/expense_tracker.yml $(ANSIBLE_FLAGS)

ping: ## Connectivity Check (Works for Talos/No-Python)
	@echo "📡 Pinging [$(ENV)] hosts..."
	ansible-playbook playbooks/ping.yml $(ANSIBLE_FLAGS)

ifeq (ssh,$(firstword $(MAKECMDGOALS)))
  SSH_SEARCH_TERM := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(SSH_SEARCH_TERM):;@:)
endif

ssh: ## SSH into a host (Usage: make ssh gateway-01)
	@ENV="$(ENV)" SEARCH_QUERY="$(SSH_SEARCH_TERM)" ./scripts/ssh_connect.sh $(ANSIBLE_FLAGS)

# --- CI / QA ---

check: ## Dry-run to see pending changes
	@echo "🔍 Dry-Run Check for [$(ENV)]..."
	ansible-playbook playbooks/vpn.yml $(ANSIBLE_FLAGS) --syntax-check
	ansible-playbook playbooks/vpn.yml $(ANSIBLE_FLAGS) --check --diff

lint: ## Lint YAML files (Excludes collections to prevent hanging)
	@echo "🧹 Linting..."
	# 🟢 Exclude massive collection folders to fix hanging
	ansible-lint playbooks/*.yml roles/* --exclude collections --exclude .collection
