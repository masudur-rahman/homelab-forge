---
globs: "**/*.{yml,yaml,j2,sh}"
---

# Code Quality Rules

- Every task must have a descriptive `name:` field.
- Use FQCN for all modules (e.g., `ansible.builtin.copy`, not `copy`).
- No hardcoded secrets in tasks or variable files — use `ansible-vault`.
- Use `become: true` only on tasks that require it, not globally on plays.
- Templates use `.j2` extension and live in `templates/` within the role.
- Use handlers for service restarts — no inline restart/reload tasks.
- Add tags to tasks for selective execution.
- No magic values — extract to `group_vars/` or role `defaults/`.
- Shell scripts: use `set -euo pipefail`, quote all variables.
- One role per service. Roles follow standard structure: `tasks/`, `templates/`, `handlers/`, `defaults/`.
