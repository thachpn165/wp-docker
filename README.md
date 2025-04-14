# WP Docker

[![Version](https://img.shields.io/badge/version-v1.1.8--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)

> **Note**: Version `v1.1.8-beta` is currently undergoing final refinements and may be subject to modifications prior to the official stable release.
---

![Terminal Menu Interface](https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/menu-screenshot.png)

## Introduction

**WP Docker** is a specialized containerization platform designed for WordPress environments, offering an intuitive, terminal-based interface for developers and system administrators.

This enterprise-grade toolkit provides a security-hardened, performance-optimized infrastructure with key features such as:
- Automated WordPress provisioning
- SSL certificate management (including Let's Encrypt and custom certs)
- Modular backup orchestration with local and cloud (Rclone) support
- Full WP-CLI integration
- Seamless cloud synchronization

The platform adopts a modular architecture supporting interchangeable web servers such as OpenResty (NGINX + Lua), Caddy Server, and OpenLiteSpeed. This flexibility allows seamless switching between stacks with automatic configuration adaptation.

Unlike conventional WordPress setups, WP Docker embraces infrastructure-as-code (IaC) principles to eliminate vendor lock-in. Its isolated containerized environment—combining Linux, PHP, and database services—ensures maximum portability, scalability, and operational consistency.


Crafted with **simplicity, user-friendliness, and extensibility** at its core, this solution runs seamlessly on both **macOS and Linux** environments.

---
## Latest Release - v1.1.8-beta
Release date: 2025-04-14

### 🚀 Added

- **Improved performance on startup and CLI commands**
  - `wpdocker` now uses `source main.sh` instead of `bash main.sh` to avoid spawning sub-shells.
  - `start_docker_if_needed` uses `docker info` instead of `docker stats` for better compatibility and speed.

- **Configuration enhancements**
  - Automatically enforces `DEBUG_MODE="false"` in `config.sh` during GitHub workflows (`dev-build.yml`, `release.yml`).

- **New i18n variables added**
  - Introduced many new `readonly` variables to support multilingual CLI prompts and logs.
  - Full list of added i18n variables included in checklist.

- **Backup & restore improvements**
  - Prompt-based logic for restoring source code and database independently.
  - Shows backup file list with timestamps before prompting for selection.
  - Validates file paths and handles relative/absolute path automatically.

- **Code architecture improvements**
  - Replaced all old `menu` files under `$FUNCTIONS_DIR/<feature>` with `prompt` functions following naming convention: `<feature>_prompt_<action>`.
  - All CLI files now interact with prompt functions inside logic files for better structure and testability.

- **Safe `load_config_file` loading**
  - Added `if declare -F load_config_file` check to prevent duplicate loading during nested sourcing.

### 🐞 Fixed

- Fixed `start_docker_if_needed` delay and fallback on macOS when Docker Desktop is slow to boot.
- Fixed potential issues when selecting storage for cloud backup (ensures correct format, skips invalid index).
- Fixed backup auto-delete not skipping `.git` or special folders.
Improved detection of domain directory and backups for edge cases.

### ♻️ Changed

- Simplified and optimized CLI wrappers across all features (backup, database, PHP, SSL, system, website).
- All CLI scripts use unified `SCRIPT_PATH` + `safe_source` pattern and validate required params.
Updated backup logic to:
  - Automatically delete backup files after successful cloud upload.
  - Fallback to local backup if cloud storage is invalid or not selected.
Refactored entire prompt system to move user-interactive logic into `prompt_*` functions instead of `menu.sh`.


*For complete changelog history, please see [CHANGELOG.md](./CHANGELOG.md)*

---
## Prerequisites

### System Requirements
- Docker and Docker Compose installed
- Git (for installation and updates)
- Bash 4.0+ (pre-installed on most Linux distributions and macOS)
- At least 1GB of RAM per WordPress site (recommended)

### macOS-Specific Requirements

Docker on macOS **cannot mount any folder** outside of the shared file system list.

After installation, you **must add `/opt`** to Docker → Settings → Resources → File Sharing:

[Docker File Sharing Documentation](https://docs.docker.com/desktop/settings/mac/#file-sharing)

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/src/install.sh -o install.sh && bash -i install.sh
```

## Usage

Once installed, simply run:

```bash
wpdocker
```

This command opens the interactive terminal menu for managing your WordPress sites.

## Key Features

### WordPress Site Management
- Create and manage multiple WordPress installations simultaneously
- Configure independent PHP versions for individual sites
- Restore WordPress source code and database from backup interactively

### Security Features
- Automatic SSL certificate deployment (Let's Encrypt, custom, or self-signed)
- Isolated container environments for enhanced security
- Advanced firewall configurations through NGINX

### Backup and Recovery
- Execute comprehensive backup solutions with cloud integration (via Rclone)
- Schedule automated periodic backups through cron functionality
- Human-readable cron schedule descriptions when setting backups
- Restore sites from previous backup points with file and database recovery

### Configuration and Monitoring
- Directly modify configuration files including `php.ini` and `php-fpm.conf`
- Monitor site health through SSL verification and log analysis
- Performance optimization tools for NGINX and PHP-FPM
- **Switch system language dynamically from the System Tools menu**
- **Full multilingual support (i18n) for CLI prompts and messages**

### System Administration
- Perform complete site removal including containers, files, and SSL certificates
- Update Docker images and system components
- Access container shells for advanced troubleshooting
- Enable global Debug Mode to show internal commands and logs
- Enable Dev Mode to preview unreleased or under-development features

## Advanced Configuration

For advanced users requiring custom configurations, the following files can be modified:

- `config/nginx/`: NGINX configuration templates
- `config/php/`: PHP version-specific configurations
- `config/mysql/`: MySQL server settings

After modifying configuration files, restart the affected services through the system menu.

## 🚀 WP Docker Roadmap (2025)

### ✅ Current Version: `v1.1.8` (Beta)
- Planned release of the first stable version (v1.2.0-stable): 2025-05-05

### Core Features Completed:
- Create WordPress websites with Docker
- PHP version management (ARM compatibility warning included)
- SSL certificate management (self-signed, Let's Encrypt, manual)
- Backup system (local + Rclone support)
- Scheduled automated backups
- Website restoration (source + database)
- Integrated WAF (OpenResty + Lua-based rules)
- Auto-update WP-CLI and system version checker
- Clean command-line interface optimized for macOS and Linux
- Automatic WordPress Migration (restore data from existing WordPress website in "one-shot")


---

### 🗓️ Upcoming Milestones

#### v1.3.0

- Refactor to support multiple web servers (OpenResty, Caddy, OpenLiteSpeed, LiteSpeed Enterprise, etc.)
- Integrate Caddy Server with WordPress using Caddy Route Cache.

#### v1.4.0

- ~Add command-line support for common tasks such as site creation, enabling/disabling cache configuration, and updating WP Docker.~ (Added in v1.1.5-beta)
- Integrate Fail2Ban for server security.
- Integrate Telegram notifications for events like backups, Fail2Ban triggers, DDoS detection, updates, SSL expiration, and health checks.

#### v1.5.0

- ~Full CLI support for all available features~ (Added in v1.1.5-beta)
- IP blocking for DDoS attacks based on access_log analysis (using Lua for OpenResty and Go for Caddy).

#### v1.6.0

- Add Webhook support to receive similar notifications.

#### v1.7.0

- Isolated sFTP/SSH access per website
- Automatically transfer site data to another server proactively

---

## Acknowledgments

I would like to extend my sincere appreciation to **[@sonpython](https://github.com/sonpython)** for his valuable contributions to this project. My heartfelt thanks also go to my colleagues at **[AZDIGI](https://azdigi.com)**: **[@dotrungquan](https://github.com/dotrungquan)** , **[@BamBo355](https://github.com/BamBo355)** , **[@phongdh262](https://github.com/phongdh262)**, and **[@RakunFatalis](https://github.com/RakunFatalis)** for their unwavering support throughout the development process.

Furthermore, I am grateful for the innovative AI tools **ChatGPT** and **Cursor**, which significantly enhanced the efficiency and quality of this project.

## Contributing

### Contribution Guidelines

1. Fork the repository to your personal GitHub account
2. Create a feature branch from the `main` branch
3. Implement your changes, commit them with descriptive messages, and submit a pull request
4. For comprehensive contribution procedures, please consult our [CONTRIBUTING.md](./CONTRIBUTING.md) documentation

### Reporting Issues
- For bugs or feature requests, please open an issue in the GitHub repository
- Include detailed information about your environment and steps to reproduce any bugs

---

## Documentation
Coming soon

---
## License

This project is licensed under the [MIT License](./LICENSE).