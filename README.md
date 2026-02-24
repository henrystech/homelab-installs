# 🐉 Henry's Linux Automation Scripts

Welcome to my personal **Gitea-hosted** collection of Bash automation
tools.

This repository serves as a centralized, version-controlled toolkit for
Linux system setup, Docker environments, NAS configuration, and homelab
automation.

------------------------------------------------------------------------

## 📌 About This Repository

This project is hosted on a private/self-managed Gitea instance and is
designed for:

-   🔧 Rapid server provisioning
-   🐳 Docker stack deployment
-   💾 NAS and storage automation
-   🔐 Permission and user management
-   🔄 System maintenance and update scripts
-   🧪 Experimental automation testing

The goal is to build **clean, repeatable, and production-aware Bash
scripts** that eliminate manual configuration errors and save time.

------------------------------------------------------------------------

## 🖥 Target Environments

Primary environments supported:

-   Ubuntu / Debian-based Linux
-   Minimal server installations
-   Docker-enabled hosts
-   UGREEN NAS environments
-   Homelab infrastructure
-   Proxmox-ready systems

Each script will document compatibility notes when required.

------------------------------------------------------------------------

## 📂 Repository Structure

Planned organization structure:

. ├── docker/ ├── installers/ ├── storage/ ├── system/ ├── network/ ├──
utilities/ └── docs/

Scripts are grouped by function to keep the repository modular and
scalable.

------------------------------------------------------------------------

## 🧠 Script Design Principles

All scripts in this repository follow these standards:

-   set -e enabled for safe execution
-   Clear console logging
-   Root privilege checks when required
-   Minimal external dependencies
-   Modular variable configuration
-   Idempotent logic where possible
-   Readable and well-commented structure

------------------------------------------------------------------------

## 🚀 Execution Philosophy

Scripts may support:

-   curl \| bash execution (for quick deployment)
-   Manual review and local execution
-   Customization via environment variables
-   Safe defaults to prevent accidental damage

⚠️ Always review scripts before running them in production environments.

------------------------------------------------------------------------

## 🔒 Disclaimer

These scripts are provided as-is without warranty.

You are responsible for reviewing and testing scripts before deploying
to production systems.

------------------------------------------------------------------------

## 📈 Roadmap

-   [ ] Arr stack automation
-   [ ] NAS-specific deployment tools
-   [ ] Proxmox VM helpers
-   [ ] Backup automation scripts
-   [ ] Logging & monitoring utilities
-   [ ] Network automation tools

------------------------------------------------------------------------

## 🤝 Contribution Policy

This is primarily a personal automation repository.\
However, improvements, suggestions, and structured pull requests are
welcome.

------------------------------------------------------------------------

Maintained by Henry Perez\
Powered by Gitea and Linux automation principles.
