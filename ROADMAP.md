# 🚀 WP Docker Roadmap (2025)

## Current Version: `v1.2.0` (Beta)

The stable version will be released later as WP Docker is undergoing a complete refactoring of its codebase to optimize performance and scalability.

## Core Features Completed:

- Create WordPress websites with Docker
- PHP version management (ARM compatibility warning included)
- SSL certificate management (self-signed, Let's Encrypt, manual)
- Backup system (local + Rclone support)
- Scheduled automated backups
- Website restoration (source + database)
- Integrated WAF (OpenResty + Lua-based rules)
- System version checker
- Clean command-line interface optimized for macOS and Linux

---

## 🗓️ Upcoming Milestones

### From v1.2.0 to v1.9.0

- Focus on stabilizing core feature functionalities
- Add new features: Telegram notification, Fail2ban integration
- Support configuration for WordPress Multisite

### v2.0.0

- Refactor to support multiple web servers
- Integrate additional web servers: Caddy Server, OpenLiteSpeed

### v3.0.0

- Enable cluster support using Docker Swarm
