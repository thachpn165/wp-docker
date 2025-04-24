<h1 align="center">WP Docker</h1>
<p align="center">Lightweight, Flexibility & Freedom</p>

> Welcome to v1.2.0-beta, the final beta version before the release of our first official stable version, v1.2.0. The launch date for v1.2.0 is May 5, 2025.

[![Version](https://img.shields.io/badge/version-v1.2.0--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![Language Support](https://img.shields.io/badge/language-Việt%20%7C%20English-blueviolet)](#)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)


---

![Terminal Menu Interface](https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/menu-screenshot.png)


- 📝 [**Documentation**](https://wpdocker.vn) (*Coming soon: Support for Vietnamese and English languages*)
- 🦠 [**Report a bug**](https://github.com/thachpn165/wp-docker/issues/new?labels=bug)
- 💡 [**Feature request**](https://github.com/thachpn165/wp-docker/issues/new?labels=bug)

## Introduction to WP Docker!

**WP Docker** makes WordPress development a breeze with its easy-to-use container platform that works right from your terminal.

Designed for both beginners and pros, it gives you everything you need to run WordPress smoothly:

- Currently supports OpenResty (NGINX with Lua), MariaDB, and PHP-FPM
- Smart resource management: Automatically configures PHP-FPM and MySQL based on your computer's capabilities
- Quick setup: Gets WordPress running with just a few commands
- Built-in caching tools: Automatically configures WordPress caching with ready-to-use setups for FastCGI Cache, Redis, WP Super Cache, WP Fastest Cache, and more
- WP-CLI ready: Run `wpdocker wp cli example.ltd <command>` to execute any WP-CLI command directly inside your container
- Enjoy flexible usage through a friendly terminal interface or the convenient `wpdocker` command line—whichever works best for you!
- Safe and secure, as WP Docker uses only official Docker images that are regularly updated (except for OpenResty, which uses my custom-built image to support Brotli compression and the `ngx_cache_purge` module)

*Soon* you'll be able to switch between different web servers like OpenResty or Caddy without changing your workflow. This exciting feature is coming in a future update, with the system automatically handling all configuration changes for you.

WP Docker adopts infrastructure-as-code principles to give you complete freedom, so you're never locked into one provider. Your entire WordPress setup—including Linux, PHP, and database—runs in containers that you can move anywhere. In the near future, WP Docker will introduce a powerful migration feature that lets you transfer your complete setup to a different server quickly and automatically—giving you true portability and freedom to host your WordPress sites wherever you want!

As an open-source project released under the MIT license, you're free to use, modify, and distribute WP Docker for any purpose, whether personal or commercial.

Built to be **simple, friendly, and flexible**, WP Docker works perfectly on both **Mac and Linux** computers. Why not give it a try?

---

## Prerequisites

### System Requirements

- It is recommended to have Docker and the Docker Compose plugin installed before install WP Docker
- Git (for installation and updates)
- Bash 3.0+ (pre-installed on most Linux distributions and macOS), but Bash 4.0 or later is recommended.
- At least 1GB of RAM per WordPress site (recommended)

### macOS-Specific Requirements

Docker on macOS **cannot access folders outside** the shared file system list.

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
wpdocker menu
```

This command opens the interactive terminal menu for managing your WordPress sites.

You can also use WP Docker through the `wpdocker` command. For more information, refer to the instructions with the `wpdocker --help` command.

## Latest Release - v1.2.0-beta

Release date: 2025-04-16

### 🚀 Added

- New command: `wpdocker core uninstall` for full removal flow
- Centralized MariaDB container with dynamic database/user creation
- Slowlog file: `logs/php_slow.log` per site (linked via `php-fpm.conf`)
- PHP error log: `logs/php_error.log` with dynamic injection into `php.ini`
- Auto-tracking of cache type into `.config.json`
- Resource-aware PHP-FPM tuning: `pm.max_children`, server tier detection
- Shared FastCGI cache volume across PHP and NGINX containers
- Added slowlog + timeout settings into `php-fpm.conf`

### ♻️ Changed

- Moved system-level scripts into `shared/core/` structure
- Removed `db_utils.sh` and legacy per-site DB containers
- Changed default `$DOCKER_NETWORK` to `wpdocker-network`
- All docker-compose files now use `${docker_network}` instead of hardcoded names

### 🐞 Fixed

- Ensured MySQL volume and container names are consistent across installs
- Fixed error when writing `php.ini` and `php-fpm.conf` when paths are missing
- Made uninstall script safely ignore `.git/` and preserve archives

*For complete changelog history, please see [CHANGELOG.md](./CHANGELOG.md)*

---

## Key Features

### WordPress Site Management

- Create and manage multiple WordPress installations simultaneously
- Configure PHP versions and its configurations for individual sites
- Restore WordPress source code and database from backup interactively

### Security Features

- Automatic SSL certificate deployment (Let's Encrypt, custom, or self-signed)
- Isolated container environments for enhanced security
- Intergrated firewall configurations through NGINX

### Backup and Recovery

- Execute comprehensive backup solutions with cloud integration (via Rclone)
- Schedule automated periodic backups through cron functionality
- Easy to restore website data from backup

### Configuration

- Directly modify configuration files including `php.ini` and `php-fpm.conf`
- Performance optimization tools for NGINX and PHP-FPM
- Full multilingual support (i18n) for CLI prompts and messages

### System Administration

- Perform complete site removal including containers, files, and SSL certificates
- Update Docker images and system components
- Access container shells for advanced troubleshooting
- Enable global Debug Mode to show internal commands and logs
- Enable Dev Mode to preview unreleased, under-development features

## Advanced Configuration

For advanced users requiring custom configurations, the following files can be modified:

- `config/nginx/`: NGINX configuration templates
- `config/php/`: PHP version-specific configurations
- `config/mysql/`: MySQL server settings

After modifying configuration files, restart the affected services through the system menu.

## 🚀 WP Docker Roadmap (2025)

### ✅ Current Version: `v1.2.0` (Beta)

- Planned release of the first stable version (v1.2.0-stable): 2025-05-05

### Core Features Completed:

- Create WordPress websites with Docker
- PHP version management (ARM compatibility warning included)
- SSL certificate management (self-signed, Let's Encrypt, manual)
- Backup system (local + Rclone support)
- Scheduled automated backups
- Website restoration (source + database)
- Integrated firewall configurations through NGINX
- Auto-update WP-CLI and system version checker
- Clean command-line interface optimized for macOS and Linux
- Automatic WordPress Migration (restore data from existing WordPress website in "one-shot")


---

### 🗓️ Upcoming Milestones

#### From v1.2.0 to v1.9.0

- Focus on stabilizing core feature functionalities
- Add new features: Telegram notification, Fail2ban integration
- Support configuration for WordPress Multisite

#### v2.0.0

- Refactor to support multiple web servers
- Integrate additional web servers: Caddy Server, OpenLiteSpeed

#### v3.0.0

- Cluster support using Docker Swarm

---

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

## License

This project is licensed under the [MIT License](./LICENSE).

---

## Credits
- [DannyBen/bashly](https://github.com/DannyBen/bashly) (MIT license)
- [rclone](https://github.com/rclone/rclone) (MIT license)

---

## Acknowledgments

I would like to extend my sincere appreciation to **[@sonpython](https://github.com/sonpython)** for his valuable contributions to this project. My heartfelt thanks also go to my colleagues at **[AZDIGI](https://azdigi.com)**: **[@dotrungquan](https://github.com/dotrungquan)** , **[@BamBo355](https://github.com/BamBo355)** , **[@phongdh262](https://github.com/phongdh262)**, and **[@RakunFatalis](https://github.com/RakunFatalis)** for their unwavering support throughout the development process.

Furthermore, I am grateful for the innovative AI tools **ChatGPT** and **Cursor**, which significantly enhanced the efficiency and quality of this project.
