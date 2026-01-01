# 🛠️ Project Forge Makefile
# Default to 'infra' to prevent accidental compute runs
ENV ?= infra

# Paths
INVENTORY_SCRIPT := ./scripts/inventory_gen.sh
INVENTORY_FILE 	 := inventories/$(ENV)/hosts.ini
PLAYBOOK         := playbooks/layer-$(ENV).yml

.PHONY: init inventory check ping config

# 📦 Install Dependencies
init:
	@echo "📦 Installing Ansible Galaxy collections..."
	ansible-galaxy install -r collections/requirements.yml --force 2>/dev/null || echo "No requirements.yml found, skipping."

# 🌉 Generate Inventory (The Bridge)
inventory:
	@echo "🌉 Generating inventory for [$(ENV)]..."
	@chmod +x $(INVENTORY_SCRIPT)
	$(INVENTORY_SCRIPT) $(ENV)

# 📡 Connectivity Check
ping:
	@echo "📡 Pinging [$(ENV)] hosts..."
	ansible -i $(INVENTORY_FILE) all -m ping

# 🚀 Run the Playbook
config:
	@echo "🚀 Configuring [$(ENV)] layer..."
	ansible-playbook -i $(INVENTORY_FILE) $(PLAYBOOK)

# 🔍 Syntax Check (Dry Run)
check:
	@echo "🔍 Checking playbook syntax for [$(ENV)]..."
	ansible-playbook -i $(INVENTORY_FILE) $(PLAYBOOK) --syntax-check
	ansible-playbook -i $(INVENTORY_FILE) $(PLAYBOOK) --check --diff

# 🧹 Linting
lint:
	@echo "🧹 Linting YAML files..."
	ansible-lint playbooks/*.yml roles/*
