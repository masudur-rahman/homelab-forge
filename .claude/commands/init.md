Onboard this project into Claude Code.

1. Read the current CLAUDE.md. If sections are empty (contain only comments), ask the user to provide:
   - What this project does (1-2 sentences)
   - Services deployed
   - Key directories
   - Any missing make targets or conventions
2. Fill in CLAUDE.md with the answers.
3. Scan the codebase: detect `ansible.cfg`, `collections/requirements.yml`, `Makefile`, role structure.
4. Run `make init` to install Galaxy collections if `collections/requirements.yml` exists.
5. Scan roles for patterns (task structure, variable naming, template usage).
6. Confirm what was written. Ask if anything is wrong or missing.
