# 📦 CHANGELOG – WP Docker LEMP

## [v1.1.6-beta] - 2025-04-05

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

---

## [v1.1.5-beta] - 2025-04-04

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

---

## [v1.1.4-beta] - 2025-04-02

### 🚀 Added
- **Refactored core functions** to adhere to the 3-step standard. This allows for better maintainability and cleaner code.
  - **Three-step structure**:
    1. **Logic functions** that contain the core functionality of each action.
    2. **CLI wrapper** that calls the logic functions and handles input parameters.
    3. **Menu functions** to interact with the user and display options.
  - This refactoring applies to various system functions such as website management, SSL management, backup management, and PHP version management.

- **Support for `wpdocker` with subcommands**:
  - Introduced subcommands for managing WordPress sites, SSL, backups, PHP versions, and more.
  - New `wpdocker` command structure:
    - **wpdocker website**: Manage WordPress websites.
      - `create`, `delete`, `list`, `restart`, `logs`, `info`, `update_template`.
    - **wpdocker ssl**: Manage SSL certificates.
      - `selfsigned`, `letsencrypt`, `check`.
    - **wpdocker backup**: Manage website backups.
      - `website`, `database`, `file`.
    - **wpdocker php**: Manage PHP configurations.
      - `change`, `get`, `rebuild`, `edit` (edit PHP config or PHP ini).

- **Alias feature** for easier command execution:
  - Created an alias for the `wpdocker` command, allowing users to use commands like `wpdocker website create`, `wpdocker ssl letsencrypt`, etc.
  - The aliases are added to the appropriate shell configuration files (`~/.bashrc` or `~/.zshrc`).
  - A helper function `check_and_add_alias` was added to check for and add aliases if they don't already exist.

### 🐞 Fixed
- **Bug fix** in handling shell configurations (alias issue):
  - Corrected the behavior when adding aliases in shell configuration files.
  - Resolved issues related to alias duplication and ensured smooth execution after reload.

### ♻️ Changed
- **Menu structure** refactor to make it more modular and user-friendly.
  - Subcommands are now managed with individual functions for clarity and ease of maintenance.
  - Centralized subcommand handling for website, SSL, backup, and PHP management under the `wpdocker` command.
  
- **Shell environment detection**:
  - Improved shell detection logic to ensure compatibility with both Bash and Zsh environments, providing more accurate behavior when modifying the shell configuration.

---

## [v1.1.3-beta] - 2025-03-29

### 🐞 Bug Fixes

- ${CHECKMARK} **Fixed infinite loop when loading `config.sh` in `backup_runner.sh`**
  - Previously, the script searched for `config.sh` by manually traversing directories (`../`), leading to an infinite loop if the file wasn't found.
  - Replaced with **smarter automatic detection of `PROJECT_DIR`**, using `realpath` and `dirname` to identify the project root directory.
  - This solution:
    - Prevents hanging issues when running via `cronjob`.
    - Ensures stable operation whether `backup_runner.sh` is called directly from shell or invoked from another script.
    - Works properly in both production and test environments (`bats`).

### ♻️ Refactor

- ♻️ Moved the common `config.sh` lookup logic to the beginning of the `backup_runner.sh` script, supporting reuse for other scripts if needed.
- ${CHECKMARK} Added support for `TEST_MODE` and `TEST_LOG_FILE` variables to prevent test logs from overwriting production logs.

---

> **Note:** This version focuses on fixing technical foundation issues in preparation for test automation restructuring and improving reliability when running automated jobs.

---

## [v1.1.2-beta] - 2025-03-29

### 🐞 Bug Fixes

- ${CHECKMARK} Fixed a bug where `select_website` did not return the selected website correctly.
- ${CHECKMARK} Ensured compatibility of `select_website` with `TEST_MODE`, auto-selecting the test site when defined.
- ${CHECKMARK} Improved fallback logic to use `select` shell keyword to ensure `SITE_NAME` is always exported correctly.

### 🛠️ Improvements

- ♻️ Refactored `select_website` function for better testability and CLI experience.
  - Displays list of available websites with clear prompts.
  - Supports test automation with `$TEST_MODE` and `$TEST_SITE_NAME`.

### 🧪 CI/CD Enhancements

- ${CHECKMARK} Added support for GitHub Actions self-hosted runner (AlmaLinux 9.3) to test compatibility on RHEL-like systems.
  - Ensured compatibility for bash scripts and BATS test environment.

---

## [v1.1.0-beta] - 2025-03-28

### 🚀 Added

- ${CHECKMARK} **NGINX Rebuild**: Added a new system tool to rebuild the NGINX proxy container. This tool stops, removes, and pulls the latest OpenResty image, followed by re-creating the NGINX container.
- ${CHECKMARK} **Backup Restore**: Enhanced website restore functionality, supporting restoring both files and database from backups.
- ${CHECKMARK} **Menu Integration**: Integrated the "Restore Backup" functionality into the system tools menu (`system_tools_menu.sh`) for easier access.
- ${CHECKMARK} **Support for Test Mode**: Improved test mode handling for better simulation and testing of backup and restore processes.
- ${CHECKMARK} **Better Output Logging**: Refined debug output for backup restore process to capture key steps and results more effectively.

### 🐞 Fixed

- ${CHECKMARK} **Test Fixes**: Fixed issues with the `backup_restore_web` test where `SITE_NAME` was not correctly set in the test environment.
- ${CHECKMARK} **Container Name Dynamic Handling**: Fixed the issue of hardcoded container names and improved dynamic handling based on environment variables.
  
### ♻️ Changed

- ♻️ **Code Refactoring**: Cleaned up and optimized backup-related functions for easier maintenance and better code readability.
- ♻️ **Container Handling**: Improved Docker container initialization checks to ensure containers are up and running before backup operations begin.
- ♻️ **Backup Naming Convention**: Standardized backup file naming convention to ensure better readability and organization of backup files.

### ${WARNING} Known Issues

- No known issues at the time of release.

---

## [v1.0.8-beta] - 2025-03-27

### 🚀 Added

- ♻️ **Refactor**: Optimized and replaced `cd` commands in scripts with `run_in_dir` functions to avoid changing the working directory, enhancing flexibility and security during execution.
- ${CHECKMARK} **Support for TEST_MODE**: Ensured `TEST_MODE` is strictly controlled in both the test environment and actual code. Added `TEST_MODE` and `TEST_ALWAYS_READY` environment variables to configuration for accurate execution in automatic testing environments.
- ${CHECKMARK} **Container and Volume Checks**: Added optimized `is_container_running` and `is_volume_exist` functions with clear debug messages to assist in checking container and volume statuses during Docker operations.
- ${CHECKMARK} **Test Enhancements**: Improved automated tests in `bats` by mocking necessary functions, avoiding errors related to the environment when running tests on GitHub Actions and real environments.
  
### 🐞 Fixed

- ${CHECKMARK} **Docker Compose Container Startup**: Fixed issues related to container startup and status checking for `nginx-proxy` to ensure accurate container startup wait and checks in different environments.
- ${CHECKMARK} **File System Permissions**: Ensured Docker configuration files and necessary files do not face permission errors when running in different environments (Linux/macOS).

### ♻️ Changed

- ♻️ **Update Script Refactoring**: Improved update and recovery script code to exclude unnecessary directories (sites, logs) and avoid losing important data during automatic update operations.
- ♻️ **Log Output Adjustments**: Fine-tuned error messages and process information in logs to make tracking and analysis easier during installation and update script execution.

---

## [v1.0.7-beta] - 2025-03-23

### 🚀 Added

- ${CHECKMARK} **Support for managing SSL certificates**: Added SSL certificate management features, including:
  - Self-signed certificate installation.
  - Let's Encrypt (free) certificate installation.
  - SSL certificate status checking, including expiration date and validity.
  - SSL certificate management in NGINX Proxy.
- ${CHECKMARK} **Backup improvements**: Enhanced backup functionality to ensure no errors occur when backing up and restoring essential configuration files and data directories.

### 🐞 Fixed

- ${CHECKMARK} **Docker Compose compatibility**: Ensured compatibility with newer Docker Compose versions, including more accurate handling of Docker containers and volumes.
- ${CHECKMARK} **Script execution in different environments**: Ensured installation and management scripts work reliably on both macOS and Linux, especially when interacting with Docker and NGINX.

### ♻️ Changed

- ♻️ **Refactor system configuration**: Improved script structure for easier extension and maintenance. Utilized shared functions and simplified SSL certificate installation steps.
- ♻️ **Improved Docker container startup checks**: Improved Docker container startup checks, particularly in cases where the `nginx-proxy` container doesn't start correctly.

### 🗑️ Removed

- ♻️ **Deprecated SSL certificate management code**: Removed obsolete SSL certificate management code, replacing it with more maintainable functions.

### 📝 Misc

- ${CHECKMARK} **Bugfixes and optimization**: Optimized code, fixed minor bugs, and improved error messages during installation and configuration checks.

---

## [v1.0.6-beta] - 2025-03-26

### 🚀 New Features

- ${CHECKMARK} **Support for running `wpdocker` commands from any directory**.
- ${CHECKMARK} **New `install.sh` script**:
  - Automatically downloads the latest release from GitHub.
  - Extracts to `/opt/wp-docker`.
  - Creates a symlink `/usr/local/bin/wpdocker`.
  - Checks the operating system and provides warnings (macOS requires `/opt` to be added to Docker File Sharing).
- ${CHECKMARK} **New `uninstall.sh` script**:
  - Allows backing up the entire site before uninstalling.
  - Cleans up container, volume, configuration, cron jobs, and source code.

### 🛠️ Improvements

- ♻️ Optimized `setup-system.sh`:
  - Checks Docker & Docker Compose status.
  - Waits for `nginx-proxy` to start before continuing.
  - Displays logs if `nginx-proxy` fails to start.
- ♻️ Improved `wpdocker.sh` script to correctly run `main.sh` from the new installation path.
- ${CHECKMARK} Support for **symlinking `/opt/wp-docker` to local source code** for easier dev/test workflows.

### 🐞 Bug Fixes

- ${CHECKMARK} Fixed `wp: Permission denied` error when running WP-CLI inside the container.
- ${CHECKMARK} Fixed mount errors on macOS due to missing directory sharing permissions.
- ${CHECKMARK} Fixed `docker-compose.override.yml` path mismatch errors.
- ${CHECKMARK} Fixed file write permission issues with `php_versions.txt`.

### 📝 Notes

- On **macOS**, Docker must add `/opt` to Docker → Settings → File Sharing to avoid mount errors.
- For local dev/test using the source code:
  ```bash
  sudo rm -rf /opt/wp-docker
  sudo ln -s ~/wp-docker-lemp/src /opt/wp-docker