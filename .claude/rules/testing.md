---
globs: "**/*.{yml,yaml}"
---

# Testing Rules

- Run `make check` (syntax-check + dry-run) after any playbook or role change.
- Run `make lint` for ansible-lint validation after changes.
- Verify idempotency: a second run should report zero changes.
- Test with `--limit` to scope changes to specific hosts when possible.
- For shell scripts: validate with `shellcheck` if available.
