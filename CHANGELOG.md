# 📦 CHANGELOG – WP Docker LEMP

## [v1.1.2-beta] - 2025-03-29

### 🐛 Bug Fixes
- Fixed a bug where `select_website` did not return the selected website correctly.
- Ensured compatibility of `select_website` with `TEST_MODE`, auto-selecting the test site when defined.
- Improved fallback logic to use `select` shell keyword to ensure `SITE_NAME` is always exported correctly.

### 🛠 Improvements
- Refactored `select_website` function for better testability and CLI experience.
  - Displays list of available websites with clear prompts.
  - Supports test automation with `$TEST_MODE` and `$TEST_SITE_NAME`.

### 🧪 CI/CD Enhancements
- Added support for GitHub Actions self-hosted runner (AlmaLinux 9.3) to test compatibility on RHEL-like systems.
  - Ensured compatibility for bash scripts and BATS test environment.

---

## [v1.1.0-beta] - 2025-03-28

### Added
- **NGINX Rebuild**: Added a new system tool to rebuild the NGINX proxy container. This tool stops, removes, and pulls the latest OpenResty image, followed by re-creating the NGINX container.
- **Backup Restore**: Enhanced website restore functionality, supporting restoring both files and database from backups.
- **Menu Integration**: Integrated the "Restore Backup" functionality into the system tools menu (`system_tools_menu.sh`) for easier access.
- **Support for Test Mode**: Improved test mode handling for better simulation and testing of backup and restore processes.
- **Better Output Logging**: Refined debug output for backup restore process to capture key steps and results more effectively.

### Fixed
- **Test Fixes**: Fixed issues with the `backup_restore_web` test where `SITE_NAME` was not correctly set in the test environment.
- **Container Name Dynamic Handling**: Fixed the issue of hardcoded container names and improved dynamic handling based on environment variables.
  
### Changed
- **Code Refactoring**: Cleaned up and optimized backup-related functions for easier maintenance and better code readability.
- **Container Handling**: Improved Docker container initialization checks to ensure containers are up and running before backup operations begin.
- **Backup Naming Convention**: Standardized backup file naming convention to ensure better readability and organization of backup files.

### Known Issues
- No known issues at the time of release.

---

## [v1.0.8-beta] - 2025-03-27

### Added
- **Refactor**: Optimized and replaced `cd` commands in scripts with `run_in_dir` functions to avoid changing the working directory, enhancing flexibility and security during execution.
- **Support for TEST_MODE**: Ensured `TEST_MODE` is strictly controlled in both the test environment and actual code. Added `TEST_MODE` and `TEST_ALWAYS_READY` environment variables to configuration for accurate execution in automatic testing environments.
- **Container and Volume Checks**: Added optimized `is_container_running` and `is_volume_exist` functions with clear debug messages to assist in checking container and volume statuses during Docker operations.
- **Test Enhancements**: Improved automated tests in `bats` by mocking necessary functions, avoiding errors related to the environment when running tests on GitHub Actions and real environments.
  
### Fixed
- **Docker Compose Container Startup**: Fixed issues related to container startup and status checking for `nginx-proxy` to ensure accurate container startup wait and checks in different environments.
- **File System Permissions**: Ensured Docker configuration files and necessary files do not face permission errors when running in different environments (Linux/macOS).

### Changed
- **Update Script Refactoring**: Improved update and recovery script code to exclude unnecessary directories (sites, logs) and avoid losing important data during automatic update operations.
- **Log Output Adjustments**: Fine-tuned error messages and process information in logs to make tracking and analysis easier during installation and update script execution.

---

## [v1.0.7-beta] - 2025-03-23

### Added
- **Support for managing SSL certificates**: Added SSL certificate management features, including:
  - Self-signed certificate installation.
  - Let's Encrypt (free) certificate installation.
  - SSL certificate status checking, including expiration date and validity.
  - SSL certificate management in NGINX Proxy.
- **Backup improvements**: Enhanced backup functionality to ensure no errors occur when backing up and restoring essential configuration files and data directories.

### Fixed
- **Docker Compose compatibility**: Ensured compatibility with newer Docker Compose versions, including more accurate handling of Docker containers and volumes.
- **Script execution in different environments**: Ensured installation and management scripts work reliably on both macOS and Linux, especially when interacting with Docker and NGINX.

### Changed
- **Refactor system configuration**: Improved script structure for easier extension and maintenance. Utilized shared functions and simplified SSL certificate installation steps.
- **Improved Docker container startup checks**: Improved Docker container startup checks, particularly in cases where the `nginx-proxy` container doesn't start correctly.

### Removed
- **Deprecated SSL certificate management code**: Removed obsolete SSL certificate management code, replacing it with more maintainable functions.

### Misc
- **Bugfixes and optimization**: Optimized code, fixed minor bugs, and improved error messages during installation and configuration checks.

---

## [v1.0.6-beta] - 2025-03-26

### 🚀 New Features
- **Support for running `wpdocker` commands from any directory**.
- **New `install.sh` script**:
  - Automatically downloads the latest release from GitHub.
  - Extracts to `/opt/wp-docker`.
  - Creates a symlink `/usr/local/bin/wpdocker`.
  - Checks the operating system and provides warnings (macOS requires `/opt` to be added to Docker File Sharing).
- **New `uninstall.sh` script**:
  - Allows backing up the entire site before uninstalling.
  - Cleans up container, volume, configuration, cron jobs, and source code.

### 🔧 Improvements
- Optimized `setup-system.sh`:
  - Checks Docker & Docker Compose status.
  - Waits for `nginx-proxy` to start before continuing.
  - Displays logs if `nginx-proxy` fails to start.
- Improved `wpdocker.sh` script to correctly run `main.sh` from the new installation path.
- Support for **symlinking `/opt/wp-docker` to local source code** for easier dev/test workflows.

### 🛠 Bug Fixes
- Fixed `wp: Permission denied` error when running WP-CLI inside the container.
- Fixed mount errors on macOS due to missing directory sharing permissions.
- Fixed `docker-compose.override.yml` path mismatch errors.
- Fixed file write permission issues with `php_versions.txt`.

### 💡 Notes
- On **macOS**, Docker must add `/opt` to Docker → Settings → File Sharing to avoid mount errors.
- For local dev/test using the source code:
  ```bash
  sudo rm -rf /opt/wp-docker
  sudo ln -s ~/wp-docker-lemp/src /opt/wp-docker
