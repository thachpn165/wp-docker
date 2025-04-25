# 🚀 WP Docker Roadmap (2025)

## Current Version: `v1.1.8` (Beta)

- Planned release of the first stable version (v1.2.0-stable): 2025-05-05

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
