## 🚀 WP Docker Roadmap (2025)

### ${CHECKMARK} Current Version: `v1.1.8` (Beta)

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

