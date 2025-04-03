# WP Docker

[![Version](https://img.shields.io/badge/version-v1.1.5--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)

> **Note**: Version `v1.1.5-beta` is currently undergoing final refinements and may be subject to modifications prior to the official stable release.

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

## Latest Release - v1.1.5-beta

### 🚀 Added
- **Refactored all references from `$site_name` to `$domain`** across the entire project for better clarity and domain-based structure.
  - Unified naming convention for folders, containers, and volumes using `$domain`.
  - Introduced backward-compatible script at `upgrade/v1.1.5-beta.sh` to automatically rename old site folders based on `.env` domain.

- **New CLI commands for database operations** under `wpdocker database`:
  - `export`, `import`, and `reset` subcommands added for centralized and clean database handling.

- **Improved site creation flow**:
  - Introduced `log_with_time` for better logging output.
  - Added `trap` cleanup logic to rollback on partial site setup failures.

- **WP-CLI wrapper helper function (`wp_cli`)**:
  - Simplifies running WP-CLI commands inside Docker containers.
  - Usage: `wp_cli user list`, `wp_cli plugin install`, etc.

- **Nightly version install support in `install.sh`**:
  - Automatically downloads from `https://github.com/thachpn165/wp-docker/releases/download/dev/wp-docker-dev.zip`.

### 🐞 Fixed
- **Fixed volume naming** for domains with `.` by auto-normalizing volume name format to match Docker's actual volume behavior.
- **Fixed macOS compatibility** in `nginx_remove_mount_docker` by using a portable `grep -vF` logic instead of `sed`.
- **Ensured `$domain` is passed correctly** from menu → CLI → logic layers.
- **Fixed emoji display issues** when used in colored terminal output.

### ♻️ Changed
- **Deprecated usage of `$site_name`** in favor of `$domain`.
  - All logic and variable references now operate on `$domain` only.
- **Removed `DEV_MODE`** flag from `install.sh`.
  - The Nightly install mode now directly triggers download from `dev` tag.
- **Improved select_website and argument parsing**:
  - Ensures `$domain` is consistently available across CLI and logic files.

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

### ${CHECKMARK} Current Version: `v1.1.5` (Beta)
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