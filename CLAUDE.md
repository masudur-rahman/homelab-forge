# Project: homelab-forge

## Overview
Ansible-based infrastructure automation for a homelab environment. Receives VMs provisioned by Terraform (homelab-genesis) and deploys services: WireGuard VPN, AdGuard DNS, Nginx ingress, PostgreSQL, Redis, and a Telegram expense tracker bot.

## Stack
- Ansible 2.16 (playbooks, roles, inventory)
- Jinja2 (templates)
- Shell scripts (helper automation)
- Docker Compose (service deployment on target hosts)

## Architecture
- `playbooks/` — Top-level playbooks (one per service/concern)
- `roles/` — Ansible roles (one per service: wireguard, adguard, ingress, database, expense_tracker, etc.)
- `inventories/` — Per-environment host inventories (infra, compute)
- `group_vars/` — Variable files per host group (all.yml, infra.yml, compute.yml)
- `vault/` — Ansible-vault encrypted secrets per group
- `scripts/` — Shell helpers (inventory rendering, SSH connect)
- `collections/` — Galaxy collection dependencies
- `files/` — Static files (WireGuard keys, etc.)

## Commands
```bash
make init              # Install Galaxy collections
make inventory         # Generate dynamic inventory
make ping ENV=infra    # Connectivity check
make configure_host    # Configure base system (user, SSH)
make gateway           # Deploy VPN + DNS + HA
make ingress           # Setup Nginx reverse proxy + SSL
make database ENV=compute  # Deploy PostgreSQL/Redis
make expense_tracker ENV=compute  # Deploy expense tracker bot
make check ENV=infra   # Dry-run syntax + diff check
make lint              # ansible-lint validation
make ssh gateway-01    # SSH into a host
```

## Conventions
- One role per service, following standard Ansible role structure (`tasks/`, `templates/`, `handlers/`, `defaults/`)
- Jinja2 templates use `.j2` extension
- Handlers for service restarts (not inline restart tasks)
- ENV-based inventory selection (`ENV=infra` or `ENV=compute`)
- Secrets encrypted with `ansible-vault` in `vault/` directory
- Docker Compose templates deployed via Jinja2 for containerized services
- Variables flow: `group_vars/all.yml` → `group_vars/<env>.yml` → `vault/<env>.yml`

## Active Context

## Learned
