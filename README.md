# WP Docker

[![Version](https://img.shields.io/badge/version-v1.1.6--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)

> **Note**: Version `v1.1.6-beta` is currently undergoing final refinements and may be subject to modifications prior to the official stable release.

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

By simplifying multi-stage environment replication (dev → staging → prod), WP Docker enhances security posture, accelerates deployment workflows, and ensures consistent performance across different infrastructures.


Crafted with **simplicity, user-friendliness, and extensibility** at its core, this solution runs seamlessly on both **macOS and Linux** environments.

## Latest Release - v1.1.6-beta
Release date: 2025-04-05

### 🚀 Added
- **WordPress Migration Tool**:
  - New feature to restore a full WordPress website (code & database) from `archives/$domain/`.
  - Automatically validates prefix, updates `wp-config.php`, checks DNS, and installs SSL.
  - Menu-driven with confirmation prompts and error recovery logic.
  - Display reminder to configure cache via main menu.
  
- **Version Channel Management**:
  - Introduced `.env` based `CORE_CHANNEL` to manage release channels: `official` or `nightly`.
  - Added CLI `core_channel_set.sh` and helpers to modify/read `.env` automatically.
  
- **Improved version update system**:
  - Rewritten into standardized 3-step structure: logic + cli + menu.
  - Separated version check for `official` and `nightly` via `core_version_main.sh` and `core_version_dev.sh`.
  - Auto-detection and display of latest version at startup menu.
  - `core_display_version.sh` now adapts to `CORE_CHANNEL` for accurate fetch.

- **New subcommand: `wpdocker system`**:
  - Includes:
    - `wpdocker system check`: view Docker resources.
    - `wpdocker system manage`: manage Docker containers.
    - `wpdocker system cleanup`: clean up Docker.
    - `wpdocker system nginx rebuild/restart`: manage NGINX proxy.

### 🐞 Fixed
- **404 error with WP Fastest Cache**:
  - Fixed by appending `try_files $uri $uri/ /index.php?$args;` into `@cachemiss`.

- **NGINX rebuild CLI path**:
  - Corrected script path issue in system tools menu.

- **`env_set_value` compatibility**:
  - Updated to use portable `sedi` helper for macOS/Linux sed compatibility.

- **Ensure prefix updated correctly in wp-config.php** after restoring database.
- **Fix access denied error** when checking tables prefix due to missing `MYSQL_PWD`.

### ♻️ Changed
- **Dev build workflow now uses `nightly` as tag** instead of `dev`.
- **Improved GitHub Actions** for CI/CD:
  - `dev-build.yml` and `release.yml` now update `version.txt` and push to repo.
  - `dev` version follows `vX.X.X-dev-timestamp` format.
- **Database reset during import**:
  - `database_import_logic` now resets database by dropping and recreating it cleanly.
- **Improved logic isolation**:
  - Various logic modules split from CLI for consistency and testability.


*For complete changelog history, please see [CHANGELOG.md](./CHANGELOG.md)*

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
- Implement multilingual and multisite configurations

### Security Features
- Automatic SSL certificate deployment (Let's Encrypt, custom, or self-signed)
- Isolated container environments for enhanced security
- Advanced firewall configurations through NGINX

### Backup and Recovery
- Execute comprehensive backup solutions with cloud integration (via Rclone)
- Schedule automated periodic backups through cron functionality
- Restore sites from previous backup points with file and database recovery

### Configuration and Monitoring
- Directly modify configuration files including `php.ini` and `php-fpm.conf`
- Monitor site health through SSL verification and log analysis
- Performance optimization tools for NGINX and PHP-FPM

### System Administration
- Perform complete site removal including containers, files, and SSL certificates
- Update Docker images and system components
- Access container shells for advanced troubleshooting

## Advanced Configuration

For advanced users requiring custom configurations, the following files can be modified:

- `config/nginx/`: NGINX configuration templates
- `config/php/`: PHP version-specific configurations
- `config/mysql/`: MySQL server settings

After modifying configuration files, restart the affected services through the system menu.

## 🚀 WP Docker Roadmap (2025)

### ✅ Current Version: `v1.1.6` (Beta)
- Planned release of the first stable version (v1.2.0-stable): 2025-04-15

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

```
#### v1.3.0
- Refactor to support multiple web servers (OpenResty, Caddy, OpenLiteSpeed, LiteSpeed Enterprise, etc.)
- Integrate Caddy Server with WordPress using Caddy Route Cache.

#### v1.4.0
- Add command-line support for common tasks such as site creation, enabling/disabling cache configuration, and updating WP Docker.
- Integrate Fail2Ban for server security.

#### v1.5.0
- ~Full CLI support for all available features~ (Added in v1.1.5-beta)
- IP blocking for DDoS attacks based on access_log analysis (using Lua for OpenResty and Go for Caddy).

#### v1.6.0
- Integrate Telegram notifications for events like backups, Fail2Ban triggers, DDoS detection, updates, SSL expiration, and health checks.
- Add Webhook support to receive similar notifications.

#### v1.7.0
- Isolated sFTP/SSH access per website
- Automatically transfer site data to another server proactively
```
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

## Documentation
Coming soon

## License

This project is licensed under the [MIT License](./LICENSE).