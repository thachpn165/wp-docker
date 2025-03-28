# WP Docker LEMP Stack

[![Version](https://img.shields.io/badge/version-v1.1.0--beta-blue)](https://github.com/thachpn165/wp-docker/releases)
[![Docker Support](https://img.shields.io/badge/Docker-ready-blue?logo=docker)](https://www.docker.com/)
[![macOS](https://img.shields.io/badge/macOS-supported-blue?logo=apple)](https://github.com/thachpn165/wp-docker)
[![Linux](https://img.shields.io/badge/Linux-supported-success?logo=linux)](https://github.com/thachpn165/wp-docker)
[![License](https://img.shields.io/github/license/thachpn165/wp-docker)](./LICENSE)

> **Note**: Version `v1.1.0-beta` is currently undergoing final refinements and may be subject to modifications prior to the official stable release.

![Terminal Menu Interface](https://raw.githubusercontent.com/thachpn165/wp-docker/refs/heads/main/menu-screenshot.png)

## Introduction

**WP Docker LEMP Stack** is a comprehensive solution for managing multiple WordPress installations through Docker, featuring an intuitive terminal-based interface. The system automates WordPress setup, SSL certificate generation, backup procedures, WP-CLI integration, and cloud synchronisation, among other essential functionalities.

This solution combines Linux, NGINX, MySQL, and PHP (LEMP) in a containerized environment, providing isolation, scalability, and simplified development workflows. Compared to traditional WordPress installations, this approach offers enhanced security, easy environment replication, and simplified maintenance.

Crafted with **simplicity, user-friendliness, and extensibility** at its core, this solution runs seamlessly on both **macOS and Linux** environments.

## Latest Release - v1.1.0-beta

### Added
- **NGINX Rebuild**: System tool to rebuild the NGINX proxy container with latest OpenResty image
- **Advanced Backup Restoration**: Enhanced functionality supporting both files and database restoration
- **Improved Menu Integration**: Streamlined access to restoration tools through the system menu
- **Test Mode Support**: Enhanced simulation capabilities for backup and restore processes
- **Comprehensive Logging**: Refined debug output for monitoring key operations

### Fixed
- **Test Environment Stability**: Resolved issues with environment variable handling in test scenarios
- **Dynamic Container Management**: Improved handling of container names based on environment variables

### Changed
- **Code Optimization**: Refactored backup functions for improved maintenance and readability
- **Container Initialization**: Enhanced pre-operation container status verification
- **Standardized Naming Conventions**: Improved organization of backup files

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
curl -fsSL https://github.com/thachpn165/wp-docker/blob/main/src/install.sh | bash
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