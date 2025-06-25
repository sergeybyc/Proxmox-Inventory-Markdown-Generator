# Proxmox Inventory Markdown Generator

This Bash script collects information about your Proxmox host, virtual machines (VM), and containers (LXC), and generates a Markdown-formatted report.

## 📦 Features

- Retrieves IP, MAC, description, status, and type of the host/VMs/LXCs
- Separates online and offline nodes into different tables
- Reads `description` from each VM/LXC configuration
- Outputs clean Markdown for easy integration into documentation or dashboards

## 🛠️ Requirements

Make sure the following packages are installed:

```bash
sudo apt update
sudo apt install -y jq qemu-guest-agent
```