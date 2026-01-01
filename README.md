# homelab-forge

Ansible post-provisioning layer for homelab infrastructure.

- Terraform (homelab-genesis) creates VMs
- Ansible (homelab-forge) configures them

Inventories are aligned with Terraform workspaces:
- infra    → gateways, VPN, edge services
- compute  → Talos, Flatcar, workloads
