# =============================================
# 🌐 I18n naming convention for the project
# ---------------------------------------------
# Use the following prefixes to categorize display strings:
#
# MSG_        - General messages
# INFO_       - Information notifications (ℹ️)
# SUCCESS_    - Success notifications (✅)
# ERROR_      - Critical error notifications (❌)
# WARNING_    - Warnings (⚠️)
# QUESTION_   - Questions for users (❓)
# LABEL_      - Field labels, UI display
# PROMPT_     - Input request strings
# TITLE_      - Menu or section titles
# CONFIRM_    - Confirmation messages (Yes/No)
# HELP_       - Detailed usage instructions
# TIP_        - Operation suggestions, usage tips
# LOG_        - Internal log messages
#
# 📐 Variable naming convention:
#   - All variable names in UPPER_SNAKE_CASE
#   - Variable name = <PREFIX> + <OBJECT> + _<ACTION/PROPERTY>
#   - No spaces or special characters
#
# Correct variable naming examples:
#   readonly MSG_WELCOME="Welcome to WP Docker!"
#   readonly ERROR_SITE_NOT_FOUND="Website not found!"
#   readonly PROMPT_ENTER_DOMAIN="Please enter domain name:"
#   readonly SUCCESS_BACKUP_DONE="Backup successful!"
#   readonly QUESTION_OVERWRITE_SITE="Do you want to overwrite the existing website?"
#   readonly LABEL_DB_PASSWORD="Database password"
# Do not (or limit) adding emojis in string values because these strings are often used with the print_msg function that already has emoji declarations (misc_utils.sh)
# 📝 Suggestions:
#   - Objects: SITE, BACKUP, DB, DOMAIN, FILE, USER, LOG, etc.
#   - Actions/properties: CREATED, FAILED, NOT_FOUND, SUCCESS, REQUIRED, EXISTED, ENTER, OVERWRITE, SELECT, etc.
#   - Separate parts with _
#
# 📌 Memory tip:
#   <PREFIX>_<OBJECT>_<DESCRIPTION> (ALL CAPS)
#   Example: ERROR_FILE_NOT_FOUND, PROMPT_ENTER_USERNAME, HELP_CACHE_CLEAN
# =============================================
# =============================================
# 🌐 MENU TITLES
# =============================================
readonly TITLE_MENU_WELCOME="WELCOME TO WP DOCKER"
readonly TITLE_MENU_MAIN="Main functions menu"
readonly TITLE_MENU_WEBSITE="WEBSITE MANAGEMENT"
readonly TITLE_MENU_SSL="SSL CERTIFICATE MANAGEMENT"
readonly TITLE_MENU_SYSTEM="SYSTEM TOOLS"
readonly TITLE_MENU_RCLONE="RCLONE MANAGEMENT"
readonly TITLE_MENU_WORDPRESS="WordPress Tools"
readonly TITLE_MENU_BACKUP="BACKUP MANAGEMENT"
readonly TITLE_MENU_PHP="PHP Management"
readonly TITLE_MENU_DATABASE="Database Management"
readonly TITLE_WEBSITE_DELETE="DELETE WEBSITE FROM SYSTEM"
readonly TITLE_CREATE_NEW_WORDPRESS_WEBSITE="CREATE NEW WORDPRESS WEBSITE"
readonly TITLE_MENU_WESBITE_CREATE="CREATE NEW WEBSITE"
readonly TITLE_BACKUP_UPLOAD="UPLOAD BACKUP TO CLOUD"
readonly TITLE_MIGRATION_TOOL="🌐 WordPress Migration Tool"
readonly IMPORTANT_RESET_DATABASE_TITLE="IMPORTANT WARNING"
readonly TITLE_SYSTEM_RESOURCES="Current system resources"

# =============================================
# 🔄 NOTIFICATIONS & COMMON LABELS
# =============================================
readonly MSG_BACK="⬅️  Go back"
readonly MSG_EXIT="🚪 Exit"
readonly MSG_EXITING="Exiting"
readonly MSG_SELECT_OPTION="🔹 Enter the corresponding menu option number: "
readonly MSG_PRESS_ENTER_CONTINUE="Press Enter to continue..."
readonly MSG_CLEANING_UP="Cleaning up"
readonly MSG_CREATED="Created"
readonly MSG_WEBSITE_EXIST="Website already exists"
readonly MSG_DOCKER_VOLUME_FOUND="Existing volume found"
readonly MSG_NOT_FOUND="Not found"
readonly MSG_START_CONTAINER="Starting container"
readonly MSG_CHECKING_CONTAINER="Checking container..."
readonly MSG_CONTAINER_READY="Container is ready"
readonly MSG_WEBSITE_SELECTED="Selected"
readonly MSG_LATEST="latest"
readonly MSG_OPERATION_CANCELLED="Action has been canceled."
readonly MSG_BACKUP_LISTING="Displaying backup list"

# =============================================
# 🐳 DOCKER & CONTAINER
# =============================================
readonly LABEL_DOCKER_STATUS="🐳 Docker Status"
readonly LABEL_DOCKER_NETWORK_STATUS="Docker Network Status"
readonly LABEL_DOCKER_NGINX_STATUS="NGINX Proxy Status"

readonly SUCCESS_DOCKER_STATUS="Docker is running"
readonly SUCCESS_DOCKER_NETWORK_STATUS="Docker Network is active"
readonly SUCCESS_DOCKER_NGINX_STATUS="NGINX Proxy is running"
readonly SUCCESS_DOCKER_NGINX_RESTART="NGINX has been successfully restarted"
readonly SUCCESS_DOCKER_NGINX_RELOAD="NGINX configuration has been reloaded"
readonly SUCCESS_DOCKER_NGINX_CREATE_DOCKER_COMPOSE_OVERRIDE="docker-compose.override.yml file has been initialized and configured"
readonly SUCCESS_DOCKER_NGINX_MOUNT_VOLUME="Resource mounted successfully"
readonly SUCCESS_CONTAINER_STOP="Container has been stopped and removed"
readonly SUCCESS_CONTAINER_VOLUME_REMOVE="Volume has been removed"
readonly SUCCESS_DIRECTORY_REMOVE="Directory has been removed"
readonly SUCCESS_COPY="Copied successfully"
readonly SUCCESS_NGINX_CONF_CREATED="NGINX configuration file created"
readonly SUCCESS_DOCKER_NGINX_MOUNT_REMOVED="Volumes mounted on NGINX have been removed"
readonly SUCCESS_DOCKER_INSTALLED="Docker has been installed."
readonly SUCCESS_DOCKER_COMPOSE_INSTALLED="Docker Compose has been installed."
readonly SUCCESS_DOCKER_NETWORK_CREATED="Docker network '%s' created successfully"
readonly SUCCESS_DOCKER_NETWORK_EXISTS="Docker network '%s' already exists"
readonly SUCCESS_DOCKER_CLEANUP_DONE="Docker cleanup completed successfully."
readonly SUCCESS_CONTAINER_RESTARTED="Container '%s' has been restarted successfully."
readonly SUCCESS_DOCKER_RUNNING="Docker is running"
readonly SUCCESS_NGINX_CONTAINER_STARTED="nginx-proxy container has been restarted successfully."
readonly SUCCESS_CONTAINER_OLD_REMOVED="Old PHP container has been removed (if any)"

readonly ERROR_DOCKER_STATUS="Docker is not running"
readonly ERROR_DOCKER_NETWORK_STATUS="Docker Network is not active"
readonly ERROR_DOCKER_NGINX_STATUS="NGINX Proxy is not running"
readonly ERROR_DOCKER_NGINX_RESTART="NGINX restart failed."
readonly ERROR_DOCKER_NGINX_STOP="NGINX shutdown failed"
readonly ERROR_DOCKER_NGINX_START="NGINX startup failed"
readonly ERROR_DOCKER_NGINX_RELOAD="NGINX configuration reload failed"
readonly ERROR_DOCKER_NGINX_MOUNT_VOLUME="Resource mounting failed"
readonly ERROR_DOCKER_DOWN="Error stopping container"
readonly ERROR_DOCKER_UP="Error starting container"
readonly ERROR_CONTAINER_NOT_READY_AFTER_30S="Container not ready after 30 seconds. Please check!"
readonly ERROR_NGINX_TEMPLATE_DIR_MISSING="NGINX template directory does not exist"
readonly ERROR_NGINX_TEMPLATE_NOT_FOUND="NGINX template file not found"
readonly ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING="Database container is not running"
readonly ERROR_DOCKER_NOT_INSTALLED="Docker is not installed. Please install Docker first."
readonly ERROR_CONTAINER_RESTART_FAILED="Cannot restart container: %s"
readonly ERROR_NGINX_STOP_REMOVE_FAILED="Cannot stop and remove nginx-proxy container."
readonly ERROR_NGINX_IMAGE_NAME_NOT_FOUND="Image name for nginx-proxy not found in docker-compose.yml."
readonly ERROR_NGINX_CONTAINER_START_FAILED="Cannot restart nginx-proxy container."
readonly ERROR_DOCKER_INSTALL_UNSUPPORTED_OS="Your operating system is not supported for automatic Docker installation."
readonly ERROR_DOCKER_COMPOSE_INSTALL_FAILED="Docker Compose installation failed."
readonly ERROR_NGINX_PROXY_NOT_RUNNING="nginx-proxy container is NOT running."
readonly ERROR_NGINX_PROXY_START_FAILED="Cannot start nginx-proxy with docker compose."
readonly ERROR_NGINX_PROXY_LOG_HINT="Please check configuration, volumes, or ports in use."
readonly ERROR_DOCKER_CONTAINER_DB_NOT_DEFINED="Database container name not found in .env. Please check."
readonly ERROR_CONTAINER_NAME_OR_ACTION_REQUIRED="Missing container or action to perform."
readonly ERROR_PHP_REBUILD_FAILED="Cannot rebuild PHP container"

readonly INFO_DOCKER_NGINX_STARTING="NGINX is being restarted"
readonly INFO_DOCKER_NGINX_RELOADING="NGINX configuration is being reloaded"
readonly INFO_DOCKER_NGINX_CREATING_DOCKER_COMPOSE_OVERRIDE="docker-compose.override.yml file is being initialized"
readonly INFO_DOCKER_NGINX_MOUNT_NOCHANGE="No changes found in mounted volumes"
readonly INFO_CREATE_DOCKER_NETWORK="Creating Docker network: %s"
readonly INFO_DOCKER_REMOVING_CONTAINER="Removing container: %s"
readonly INFO_DOCKER_REMOVING_VOLUME="Removing volume: %s"
readonly INFO_CONTAINER_LOG_STREAM="Viewing logs for container: %s"
readonly INFO_DOCKER_GROUP_MAC="On macOS, users don't need to be added to Docker group."
readonly INFO_DOCKER_GROUP_ADDING="Adding user '%s' to Docker group..."
readonly INFO_NGINX_PROXY_STARTING="nginx-proxy container not started. Starting..."
readonly INFO_NGINX_PROXY_WAIT="Checking nginx-proxy container status..."

readonly WARNING_REMOVE_OLD_NGINX_CONF="Removing old NGINX configuration"
readonly SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST="Resource already exists"
readonly WARNING_DOCKER_NOT_RUNNING="Docker is not running. Starting Docker..."
readonly WARNING_REMOVE_CORE_CONTAINERS="Removing core containers: nginx-proxy and redis-cache"
readonly WARNING_REMOVE_SITE_CONTAINERS="Removing containers for website: %s"

readonly DEBUG_DOCKER_NETWORK_EXISTS="Docker network '%s' exists"
readonly DEBUG_DOCKER_NETWORK_NOT_EXISTS="Docker network '%s' does not exist"

readonly STEP_DOCKER_CLEANUP_START="Cleaning up unused Docker resources..."
readonly STEP_DOCKER_REMOVE_UNUSED_NETWORKS="Removing unused Docker networks..."
readonly STEP_CONTAINER_RESTARTING="Restarting container: %s"
readonly STEP_NGINX_REBUILD_START="Rebuilding nginx-proxy container..."
readonly STEP_DOCKER_INSTALL="Installing Docker..."
readonly STEP_DOCKER_COMPOSE_INSTALL="Installing Docker Compose plugin..."
readonly STEP_NGINX_RELOADING="Restarting nginx-proxy container..."

# =============================================
# 🌐 WEBSITE MANAGEMENT
# =============================================
readonly LABEL_MENU_WEBISTE_CREATE="Create new website"
readonly LABEL_MENU_WEBSITE_DELETE="Delete website"
readonly LABEL_MENU_WEBSITE_LIST="Website list"
readonly LABEL_MENU_WEBSITE_RESTART="Restart website"
readonly LABEL_MENU_WEBSITE_LOGS="View website logs"
readonly LABEL_MENU_WEBSITE_INFO="View website information"
readonly LABEL_MENU_WEBSITE_UPDATE_TEMPLATE="Update configuration template"
readonly LABEL_WEBSITE_INFO="Website information for "
readonly LABEL_WEBSITE_DOMAIN="Domain name"
readonly LABEL_WEBSITE_DB_NAME="Database name"
readonly LABEL_WEBSITE_DB_USER="Database username"
readonly LABEL_WEBSITE_DB_PASS="Database password"
readonly LABEL_SITE_DIR="Website directory"
readonly LABEL_WEBSITE_LIST="Website list"

readonly PROMPT_ENTER_DOMAIN="Enter website domain (e.g.: azdigi.com)"
readonly PROMPT_WEBSITE_CREATE_RANDOM_ADMIN="Do you want the system to generate a strong password for admin? [Y/n]:"
readonly PROMPT_BACKUP_BEFORE_DELETE="Do you want to backup website data before deleting? (RECOMMENDED)"
readonly PROMPT_WEBSITE_DELETE_CONFIRM="Are you sure you want to delete the website?"
readonly PROMPT_WEBSITE_SELECT="🔹 Select a website: "
readonly PROMPT_CHOOSE_ACTION_FOR_SITE="📋 Choose an action for website '%s':"
readonly PROMPT_ENTER_OPTION="Enter the number corresponding to the action:"
readonly PROMPT_WEBSITE_CREATE_CONFIRM="Do you want to create website '%s' before migrating?"

readonly ERROR_NO_WEBSITES_FOUND="No websites found"
readonly ERROR_NOT_EXIST="does not exist"
readonly ERROR_ENV_NOT_FOUND=".env file not found"
readonly ERROR_SITE_NOT_SELECTED="You haven't selected any website."
readonly ERROR_SITE_NOT_EXIST="Website '%s' does not exist"
readonly ERROR_DOMAIN_NOT_FOUND=".env does not contain DOMAIN variable"
readonly ERROR_WORDPRESS_DIR_NOT_FOUND="Source code directory not found: %s"
readonly ERROR_FILE_NOT_FOUND="File not found: %s"
readonly ERROR_DOMAIN_NOT_POINT_TO_SERVER="Domain '%s' does NOT point to server IP: %s. Please update DNS."
readonly ERROR_PARAM_SITE_NAME_REQUIRED="Missing website name parameter (--domain)"

readonly SUCCESS_WEBSITE_REMOVED="Website removal completed"
readonly SUCCESS_WEBSITE_RESTART="Website restart completed"
readonly SUCCESS_DOMAIN_POINTS_TO_IP="Domain '%s' correctly points to IP: %s"
readonly SUCCESS_MIGRATION_DONE="Migration process completed for '%s'."

readonly MSG_WEBSITE_BACKUP_BEFORE_REMOVE="Creating backup before deletion..."
readonly MSG_WEBSITE_BACKING_UP_DB="Backing up database"
readonly MSG_WEBSITE_BACKING_UP_FILES="Backing up source code"
readonly MSG_WEBSITE_BACKUP_FILE_CREATED="Backup completed and stored"
readonly MSG_WEBSITE_STOPPING_CONTAINERS="Stopping website containers"
readonly MSG_NGINX_REMOVE_MOUNT="Removing volume configuration in NGINX"
readonly MSG_WEBSITE_DELETING_DIRECTORY="Deleting website directory"
readonly MSG_WEBSITE_DELETING_SSL="Deleting website SSL certificate"
readonly MSG_WEBSITE_DELETING_VOLUME="Deleting database volume"
readonly MSG_WEBSITE_DELETING_NGINX_CONF="Deleting website NGINX configuration"
readonly MSG_DOCKER_NGINX_RESTART="Restarting NGINX"
readonly MSG_WEBSITE_PERMISSIONS="Checking and setting permissions"

readonly STEP_WEBSITE_SETUP_NGINX="Setting up NGINX"
readonly STEP_WEBSITE_SETUP_COPY_CONFIG="Copying template configuration"
readonly STEP_WEBSITE_SETUP_APPLY_CONFIG="Calculating automatic MariaDB & PHP configuration"
readonly STEP_WEBSITE_SETUP_CREATE_ENV="Creating .env file for website"
readonly STEP_WEBSITE_SETUP_CREATE_SSL="Creating self-signed SSL certificate for website"
readonly STEP_WEBSITE_SETUP_CREATE_DOCKER_COMPOSE="Setting up docker-compose.yml for website"
readonly STEP_WEBSITE_SETUP_WORDPRESS="Installing WordPress"
readonly STEP_WEBSITE_SETUP_ESSENTIALS="Configuring basics (permalinks, security plugins,...)"
readonly STEP_WEBSITE_RESTARTING="Restarting website"
readonly STEP_WEBSITE_CHECK_DNS="Checking domain pointing"

# =============================================
# 📦 WORDPRESS
# =============================================
readonly INFO_START_WP_INSTALL="Starting WordPress installation for"
readonly INFO_WAITING_PHP_CONTAINER="Waiting for PHP container"
readonly INFO_DOWNLOADING_WP="Downloading WordPress source code..."
readonly INFO_SITE_URL="🌐 Website"
readonly INFO_ADMIN_URL="👤 Admin page"
readonly INFO_ADMIN_USER="👤 Admin account"
readonly INFO_ADMIN_PASSWORD="🔐 Admin password"
readonly INFO_ADMIN_EMAIL="📧 Admin email"
readonly INFO_WORDPRESS_LIST_ADMINS="📋 List of Admin accounts:"
readonly INFO_PLUGIN_STATUS="📋 Current plugin status on '%s':"
readonly INFO_INSTALLING_SSL="Installing SSL for %s..."
readonly INFO_SKIP_SSL_INSTALL="Skipping SSL installation."
readonly INFO_WP_CONFIGURING="Configuring wp-config.php file in container..."
readonly INFO_WP_INSTALLING="Installing WordPress..."
readonly INFO_WPCLI_CURRENT="Current WP-CLI version: v%s"
readonly INFO_WPCLI_UPDATING="Checking and updating WP-CLI..."

readonly SUCCESS_WP_SOURCE_DOWNLOADED="WordPress source code downloaded."
readonly SUCCESS_WP_SOURCE_EXISTS="WordPress source code already exists."
readonly SUCCESS_WP_INSTALL_DONE="WordPress installation completed."
readonly SUCCESS_WP_CONFIG_DONE="wp-config.php file has been configured successfully"
readonly SUCCESS_WP_INSTALLED="WordPress has been installed successfully"
readonly SUCCESS_WP_SECURITY_PLUGIN="Security plugin has been installed and activated"
readonly SUCCESS_WP_PERFORMANCE_PLUGIN="Performance plugin has been installed and activated"
readonly SUCCESS_WPCLI_UPDATED="WP-CLI has been updated to version: v%s"
readonly SUCCESS_WPCLI_INSTALLED="WP-CLI installed successfully."
readonly SUCCESS_WPCLI_EXISTS="WP-CLI already exists at %s."
readonly SUCCESS_PLUGIN_AUTO_UPDATE_ENABLED="Automatic plugin updates enabled for website '%s'."
readonly SUCCESS_PLUGIN_AUTO_UPDATE_DISABLED="Automatic plugin updates disabled for website '%s'."
readonly SUCCESS_WORDPRESS_UPDATE_PREFIX="Prefix updated successfully."
readonly SUCCESS_WORDPRESS_RESET_ADMIN_PASSWD="Admin password has been reset successfully. Please save the new password for "
readonly SUCCESS_WORDPRESS_RESET_ROLE="Admin role has been reset successfully for %s."
readonly SUCCESS_PLUGIN_DEACTIVATED="Plugin %s has been deactivated successfully."
readonly SUCCESS_PLUGIN_DELETED="Plugin %s has been deleted successfully."
readonly SUCCESS_CACHE_DISABLED="Cache has been disabled and NGINX reloaded"
readonly SUCCESS_WORDPRESS_CHOOSE_CACHE="Selected cache type: "
readonly SUCCESS_UPDATE_NGINX_CACHE_TYPE="NGINX configuration updated with cache type: %s"
readonly SUCCESS_FASTCGI_PATH_ADDED="FastCGI Cache configuration added to NGINX"

readonly ERROR_PHP_CONTAINER_NOT_READY="PHP container not ready after 30s"
readonly ERROR_WP_INSTALL_FAILED="WordPress installation failed."
readonly ERROR_PERMISSION_SETTING="Cannot set directory permissions."
readonly ERROR_WPCLI_INVALID_PARAMS="You must provide a WP-CLI command to execute"
readonly ERROR_WP_CONFIG_FAILED="Cannot configure wp-config.php"
readonly ERROR_WP_PERMALINK_FAILED="Permalink setup failed"
readonly ERROR_WP_SECURITY_PLUGIN="Security plugin installation failed"
readonly ERROR_WP_PERFORMANCE_PLUGIN="Performance plugin installation failed"
readonly ERROR_WPCLI_DOWNLOAD_FAILED="WP-CLI download failed."
readonly ERROR_WPCLI_MOVE_FAILED="Moving wp-cli.phar file failed."
readonly ERROR_WORDPRESS_RESET_ADMIN_PASSWD="Cannot reset password for Admin account. Please check the account ID."
readonly ERROR_WORDPRESS_RESET_ROLE="Cannot reset role for Admin account."
readonly ERROR_PLUGIN_DEACTIVATION="Error deactivating plugin: %s"
readonly ERROR_PLUGIN_DELETION="Error deleting plugin: %s"
readonly ERROR_REMOVE_WP_CACHE_DEFINE="Error removing WP_CACHE line in wp-config.php"
readonly ERROR_UPDATE_NGINX_NO_CACHE="Error updating NGINX to no-cache mode"
readonly ERROR_UPDATE_NGINX_CACHE_TYPE="Error updating NGINX configuration for cache type"
readonly ERROR_NGINX_INCLUDE_NOT_FOUND="Cache include line not found in NGINX configuration"
readonly ERROR_PLUGIN_INSTALL="Error installing and activating cache plugin"
readonly ERROR_CHOWN_WPCONTENT="Error setting permissions for wp-content"
readonly ERROR_ADD_FASTCGI_PATH="Error adding fastcgi_cache_path to nginx.conf"
readonly ERROR_UPDATE_NGINX_HELPER="Error updating Nginx Helper options"
readonly ERROR_REDIS_PLUGIN_INSTALL="Error installing Redis Cache plugin"
readonly ERROR_REDIS_UPDATE_DROPIN="Error updating Redis drop-in"
readonly ERROR_REDIS_UPDATE_OPTIONS="Error updating Redis Cache options"
readonly ERROR_REDIS_ENABLE="Error enabling Redis Cache"

readonly WARNING_SKIP_CHOWN="Skipping chown because PHP container is not ready."
readonly WARNING_ADMIN_USERNAME_EMPTY="Username cannot be empty."
readonly WARNING_ADMIN_PASSWORD_MISMATCH="Passwords do not match or are empty. Please try again."
readonly WARNING_WPCLI_NOT_FOUND="WP-CLI not installed. Installing now..."
readonly WARNING_RESET_ADMIN_ROLE_1="This function will reset Administrator role to default."
readonly WARNING_RESET_ADMIN_ROLE_2="Use this when Admin account has lost permissions or cannot access."
readonly WARNING_PLUGIN_ACTIVE_DEACTIVATING="Plugin %s is active, it will be deactivated."
readonly WARNING_CACHE_REMOVING="Removing cache plugin and disabling WP_CACHE..."
readonly WARNING_PLUGIN_ACTIVE_DELETING="Plugin %s is active, it will be deleted..."
readonly WARNING_TABLE_PREFIX_MISMATCH="table_prefix does not match: DB='%s' | wp-config='%s'. Updating..."

readonly PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME="👤 Enter username"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD="🔑 Enter password"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM="🔑 Confirm password"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL="📫 Enter email address"
readonly PROMPT_ENTER_ADMIN_USER_ID="👉 Enter ID of the account to reset password:"
readonly PROMPT_WORDPRESS_ENTER_USER_ID="Enter ID of the account to operate on: "
readonly PROMPT_WORDPRESS_CHOOSE_CACHE="Please select the Cache type you want to use: "

readonly QUESTION_PROTECT_WPLOGIN_ACTION="What action do you want to perform for website '%s'?"
readonly QUESTION_INSTALL_SSL="Do you want to install a free SSL certificate from Let's Encrypt now?"

readonly LABEL_MENU_WORDPRESS_RESET_ADMPASSWD="Reset Admin password"
readonly LABEL_MENU_WORDPRESS_EDIT_USER_ROLE="Reset user role"
readonly LABEL_MENU_WORDPRESS_AUTO_UPDATE_PLUGIN="Enable/Disable automatic Plugin updates"
readonly LABEL_MENU_WORDPRESS_PROTECT_WPLOGIN="Enable/Disable wp-login.php protection"
readonly LABEL_MENU_WORDPRESS_MIGRATION="Migrate WordPress data to WP Docker"
readonly LABEL_ENABLE_AUTO_UPDATE_PLUGIN="Enable automatic plugin updates"
readonly LABEL_DISABLE_AUTO_UPDATE_PLUGIN="Disable automatic plugin updates"
readonly LABEL_PROTECT_WPLOGIN_ENABLE="Enable wp-login.php protection"
readonly LABEL_PROTECT_WPLOGIN_DISABLE="Disable wp-login.php protection"

readonly STEP_WORDPRESS_UPDATE_CONFIG_DB="Updating database configuration in wp-config.php"
readonly STEP_WORDPRESS_CHECK_DB_PREFIX="Checking database prefix"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_CONF_FILE="Creating configuration file to protect wp-login.php"
readonly STEP_WORDPRESS_PROTECT_WP_INCLUDE_NGINX="Setting up NGINX to protect wp-login.php"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_DIR="Creating directory for wp-login.php protection configuration"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_DISABLE="Disabling wp-login.php protection"
readonly STEP_WORDPRESS_RESET_ROLE="Resetting role for Admin account"

readonly IMPORTANT_WORDPRESS_PROTECT_WP_LOGIN_INSTALLED="wp-login.php has been protected, please save the information below to login:"

readonly TIP_MIGRATION_COMPLETE_USE_CACHE="Run 'wpdocker' and select 'Set up WordPress Cache' to optimize performance."
readonly TIP_WP_SUPER_CACHE="WP Super Cache configuration guide: Go to WP Admin → Settings → WP Super Cache, enable 'Caching On', select 'Expert'."
readonly TIP_W3_TOTAL_CACHE="W3 Total Cache configuration guide: Go to WP Admin → Performance → General Settings, enable Page/Object/Database Cache."
readonly TIP_WP_FASTEST_CACHE="WP Fastest Cache configuration guide: Go to WP Admin → WP Fastest Cache, enable 'Enable Cache' and select appropriate system."

# =============================================
# 🔒 SSL & SECURITY
# =============================================
readonly LABEL_MENU_SSL_SELFSIGNED="Create self-signed certificate"
readonly LABEL_MENU_SSL_MANUAL="Install certificate manually (paid)"
readonly LABEL_MENU_SSL_EDIT="Edit certificate"
readonly LABEL_MENU_SSL_LETSENCRYPT="Install free certificate from Let's Encrypt"
readonly LABEL_MENU_SSL_CHECK="Check certificate information"
readonly LABEL_SSL_DOMAIN="Domain name"
readonly LABEL_SSL_ISSUER="Issuer"
readonly LABEL_SSL_START_DATE="Valid from"
readonly LABEL_SSL_END_DATE="Expires on"
readonly LABEL_SSL_STATUS="Status"

readonly SUCCESS_SSL_CERTIFICATE_REMOVED="SSL certificate removed"
readonly SUCCESS_SSL_UPDATED_FOR_DOMAIN="SSL certificate updated successfully for website: %s"
readonly SUCCESS_SSL_SELF_SIGNED_GENERATED="Self-signed SSL certificate regenerated successfully for %s"
readonly SUCCESS_SSL_INSTALLED="SSL certificate installed successfully"
readonly SUCCESS_SSL_MANUAL_SAVED="Certificate has been manually installed successfully"
readonly SUCCESS_LE_CERTIFICATE_INSTALLED="Let's Encrypt certificate has been issued successfully"
readonly SUCCESS_LE_INSTALLED="Let's Encrypt has been successfully installed for website %s"
readonly SUCCESS_NGINX_RELOADED="NGINX Proxy has been reloaded successfully"

readonly ERROR_SSL_CERT_NOT_FOUND="Certificate file not found: %s"
readonly ERROR_SSL_CERT_NOT_FOUND_FOR_DOMAIN="SSL certificate not found for domain: %s"
readonly ERROR_SSL_SELF_SIGNED_GENERATE_FAILED="Cannot generate self-signed SSL certificate"
readonly ERROR_CERTBOT_NOT_SUPPORTED_OS="Operating system not supported for automatic certbot installation"
readonly ERROR_CERTBOT_NOT_SUPPORTED_MAC="Automatic certbot installation only supports Linux. Please install manually on macOS."
readonly ERROR_LE_CERTIFICATE_NOT_FOUND="Certificate not found after issuance. Please check domain and configuration."
readonly ERROR_CERTBOT_NOT_INSTALLED="Certbot not installed. Installing now..."
readonly ERROR_CERTBOT_INSTALL_MAC="Cannot install certbot on macOS. Please install manually."
readonly ERROR_CERTBOT_INSTALL_UNSUPPORTED_OS="Cannot install certbot on this operating system. Please install manually."
readonly ERROR_SSL_FILE_EMPTY_OR_MISSING=".crt or .key file missing or empty"

readonly INFO_SSL_CHECKING_FOR_DOMAIN="Checking SSL certificate for domain: %s"
readonly INFO_SSL_EDITING_FOR_DOMAIN="Editing SSL certificate for website: %s"
readonly INFO_SSL_RELOADING_NGINX="Reloading NGINX Proxy to apply new certificate..."
readonly INFO_DOMAIN_SELECTED=:"Domain selected"
readonly INFO_SSL_CERT_PATH="SSL certificate path: %s"
readonly INFO_SSL_KEY_PATH="SSL private key path: %s"
readonly INFO_LE_DOMAIN="Domain name: %s"

readonly WARNING_CERTBOT_NOT_INSTALLED="Certbot not installed. Installing now..."

readonly PROMPT_SSL_ENTER_NEW_CRT="Please paste the new content of the SSL certificate (*.crt) for %s:"
readonly PROMPT_SSL_ENTER_NEW_KEY="Please paste the new content of the private key (*.key) for %s:"

readonly STEP_SSL_REGENERATE_SELF_SIGNED="Regenerating self-signed SSL certificate for website: %s"
readonly STEP_LE_REQUESTING_CERT="Requesting Let's Encrypt certificate using webroot method..."
readonly STEP_REQUEST_CERT_WEBROOT="Requesting Let's Encrypt certificate using webroot method..."
readonly STEP_SSL_LETSENCRYPT="Installing free SSL certificate from Let's Encrypt"

# =============================================
# 💾 BACKUP & RESTORE
# =============================================
readonly LABEL_MENU_BACKUP_NOW="Backup website now"
readonly LABEL_MENU_BACKUP_MANAGE="Manage Backups"
readonly LABEL_MENU_BACKUP_SCHEDULE="Schedule automatic backups"
readonly LABEL_MENU_BACKUP_SCHEDULE_MANAGE="Manage backup schedule"
readonly LABEL_MENU_BACKUP_RESTORE="Restore data"
readonly LABEL_MENU_BACKUP_UPLOAD="Upload backup to cloud (Rclone)"
readonly LABEL_BACKUP_FILE_LIST="Backup Files"
readonly LABEL_BACKUP_DB_LIST="Database Backup"
readonly LABEL_BACKUP_LOCAL="Store on server (local)"
readonly LABEL_BACKUP_CLOUD="Store in configured Storage"
readonly LABEL_FREQUENCY="Frequency"
readonly LABEL_LOG_PATH="Log path"

readonly SUCCESS_BACKUP_CLEAN="Backup cleanup completed"
readonly SUCCESS_BACKUP_RESTORED_FILE="Source code restored successfully"
readonly SUCCESS_BACKUP_RESTORED_DB="Database restoration completed"
readonly SUCCESS_CRON_CREATED="Backup schedule set up successfully!"
readonly SUCCESS_RCLONE_UPLOAD_SINGLE="Upload successful: %s"
readonly SUCCESS_RCLONE_UPLOAD_DONE="Backup upload completed"

readonly ERROR_BACKUP_INVALID_ACTION="Invalid action, use list or clean action"
readonly ERROR_BACKUP_RESTORE_FILE_MISSING_PARAMS="Missing parameters: Backup file or website directory invalid"
readonly ERROR_BACKUP_RESTORE_FAILED="Error occurred during data restoration"
readonly ERROR_BACKUP_RESTORE_DB_MISSING_PARAMS="Missing parameters: Backup path, container name or website domain invalid"
readonly ERROR_BACKUP_FAILED_FETCH_DB_NAME_ENV="Cannot get database name from .env file. Please check this file."
readonly ERROR_BACKUP_PASSWD_NOT_FOUND="Missing MYSQL_ROOT_PASSWORD in .env or incorrect. Cannot restore database."
readonly ERROR_BACKUP_ENV_FILE_NOT_FOUND=".env file not found at"
readonly ERROR_BACKUP_MANAGE_MISSING_PARAMS="Missing parameters. Make sure you have --domain and --action parameters."
readonly ERROR_BACKUP_DIR_NOT_EXIST_CREATE="Backup directory does not exist. Creating: %s"
readonly ERROR_BACKUP_CREATE_DIR_FAILED="Cannot create backup directory."
readonly ERROR_BACKUP_DB_DUMP_FAILED="Cannot backup database: %s"
readonly ERROR_BACKUP_FILE="Error backing up source code"
readonly ERROR_RCLONE_UPLOAD_FAILED_SINGLE="Upload failed: %s"
readonly ERROR_RCLONE_CANNOT_DETECT_SITE="Cannot determine website name from file path"
readonly ERROR_BACKUP_FOLDER_NOT_FOUND="Backups folder not found"
readonly ERROR_BACKUP_NO_FILE_SELECTED="No files selected for upload"
readonly ERROR_BACKUP_FILE_NOT_FOUND="No backup files in this directory"
