# Gemini Configuration for homelab-forge

## Overview
Ansible-based infrastructure automation for a homelab environment. This project manages post-provisioning for VMs created by Terraform (homelab-genesis), deploying services like WireGuard, AdGuard Home, Nginx ingress, PostgreSQL, Redis, and a Telegram bot.

## Core Mandates & Workflow (Strict)
1.  **Ask:** Targeted questions BEFORE coding (max 1 round).
2.  **Plan:** Detailed implementation outline before any change.
3.  **Approve:** Wait for explicit user approval before proceeding.
4.  **Implement:** Code according to the approved plan.
5.  **Test:** Immediate report of pass/fail (using `make check` and `make lint`).
6.  **Review:** Self-review using the Reviewer persona criteria.
7.  **Remember:** Append new learnings to the `## Learned` section in `CLAUDE.md`.

## Persona Roles
-   **Planner:** Create plans in `.claude/plan.md` (gitignored). Do NOT write code. Max 10 file changes per plan.
-   **Refactorer:** Improve clarity/structure without adding features. One refactor at a time. Must pass `make check` and `make lint`.
-   **Reviewer:** Report findings after implementation. Focus on idempotency, handler usage, variable precedence, secret exposure (vault), FQCN usage, and tag coverage.

## Code Quality Standards
-   **Task Naming:** Every task must have a descriptive `name:`.
-   **FQCN:** Always use Fully Qualified Collection Names (e.g., `ansible.builtin.copy`).
-   **Secrets:** Never hardcode secrets. Use `ansible-vault` in the `vault/` directory.
-   **Privilege Escalation:** Use `become: true` only on tasks that require it, not globally.
-   **Templates:** Use `.j2` extension and store in role `templates/`.
-   **Handlers:** Use handlers for service restarts/reloads. No inline restart tasks.
-   **Tags:** Add tags to tasks for selective execution.
-   **Variables:** No magic values. Extract to `group_vars/` or role `defaults/`.
-   **Scripts:** Use `set -euo pipefail` and quote all variables in shell scripts.
-   **Structure:** One role per service. Standard structure: `tasks/`, `templates/`, `handlers/`, `defaults/`.

## Testing & Verification
-   **Syntax & Dry-run:** Run `make check ENV=<env>` after any playbook or role change.
-   **Linting:** Run `make lint` for `ansible-lint` validation.
-   **Idempotency:** Verify that a second run reports zero changes.
-   **Scoping:** Use `--limit` to scope changes to specific hosts when possible.

## Project Architecture & Conventions
-   **Inventories:** `infra` (gateways, VPN) and `compute` (workloads).
-   **Variable Precedence:** `group_vars/all.yml` → `group_vars/<env>.yml` → `vault/<env>.yml`.
-   **Docker:** Services are often containerized using Docker Compose templates via Jinja2.

## Key Commands
-   `make init`: Install Galaxy collections.
-   `make inventory`: Generate dynamic inventory.
-   `make ping ENV=<env>`: Connectivity check.
-   `make configure_host`: Base system setup.
-   `make check ENV=<env>`: Dry-run syntax + diff check.
-   `make lint`: Run `ansible-lint`.
-   `make <service> ENV=<env>`: Deploy a specific service (e.g., `make gateway`, `make database`).

## Permissions
Allowed commands include: `make`, `ansible-playbook`, `ansible-lint`, `ansible-galaxy`, `ansible-inventory`, `ansible-vault`, `./scripts/*`, `ssh`, `terraform`, `kubectl`, `docker`, `git`, `ls`.
**Denied:** `rm -rf /`, `rm -rf ~`, `rm -rf .`, `sudo`.
