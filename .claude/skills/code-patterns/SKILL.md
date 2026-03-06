---
name: code-patterns
description: Reference for Ansible role patterns and conventions. Read before creating new roles or modifying existing ones.
user-invocable: false
---

# Ansible Role Patterns

Read existing roles to discover patterns before writing new ones.

## Discovery Process
1. Find 2-3 similar existing roles to what you're creating.
2. Note: task structure, variable naming, template patterns, handler usage.
3. Check standard role directories: `tasks/`, `templates/`, `handlers/`, `defaults/`, `vars/`.
4. Follow the same patterns exactly.

## Key Patterns
- Tasks in `tasks/main.yml`, broken into includes if complex.
- Templates in `templates/` with `.j2` extension.
- Handlers in `handlers/main.yml` for service restart/reload.
- Default variables in `defaults/main.yml`, overridden by `group_vars/`.
- Docker Compose services use Jinja2 templates for config injection.

## If No Pattern Exists
- Ask the user which existing role to use as reference.
- Do not invent new patterns without approval.
