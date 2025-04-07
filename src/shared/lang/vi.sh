# =============================================
# 🌐 Quy ước đặt tên biến i18n trong dự án
# ---------------------------------------------
# Sử dụng các tiền tố sau để phân loại chuỗi hiển thị:
#
# MSG_        - Thông điệp chung
# INFO_       - Thông báo thông tin (ℹ️)
# SUCCESS_    - Thông báo thành công (✅)
# ERROR_      - Thông báo lỗi nghiêm trọng (❌)
# WARNING_    - Cảnh báo (⚠️)
# QUESTION_   - Câu hỏi cho người dùng (❓)
# LABEL_      - Nhãn trường dữ liệu, hiển thị UI
# PROMPT_     - Chuỗi yêu cầu nhập liệu
# TITLE_      - Tiêu đề menu hoặc section
# CONFIRM_    - Câu xác nhận (Yes/No)
# HELP_       - Hướng dẫn sử dụng chi tiết
# TIP_        - Gợi ý thao tác, mẹo sử dụng
# LOG_        - Thông điệp ghi log nội bộ
#
# 📐 Quy ước đặt tên biến:
#   - Viết HOA toàn bộ tên biến (UPPER_SNAKE_CASE)
#   - Tên biến = <TIỀN_TỐ> + <ĐỐI_TƯỢNG> + _<HÀNH_ĐỘNG/TÍNH_CHẤT>
#   - Không dùng dấu cách hoặc dấu đặc biệt
#
# Ví dụ đặt tên biến đúng:
#   readonly MSG_WELCOME="Chào mừng đến với WP Docker!"
#   readonly ERROR_SITE_NOT_FOUND="Không tìm thấy website!"
#   readonly PROMPT_ENTER_DOMAIN="Vui lòng nhập tên miền:"
#   readonly SUCCESS_BACKUP_DONE="Sao lưu thành công!"
#   readonly QUESTION_OVERWRITE_SITE="Bạn có muốn ghi đè website đã tồn tại không?"
#   readonly LABEL_DB_PASSWORD="Mật khẩu cơ sở dữ liệu"
# Không (hoặc hạn chế) đặt emoji ở giá trị chuỗi vì các chuỗi này thường sử dụng với hàm print_msg đã có khai báo emoji phù hợp (misc_utils.sh)
# 📝 Gợi ý:
#   - Đối tượng: SITE, BACKUP, DB, DOMAIN, FILE, USER, LOG, v.v.
#   - Hành động/tính chất: CREATED, FAILED, NOT_FOUND, SUCCESS, REQUIRED, EXISTED, ENTER, OVERWRITE, SELECT, v.v.
#   - Tách các phần bằng dấu _
#
# 📌 Mẹo nhớ:
#   <TIỀN_TỐ>_<ĐỐI_TƯỢNG>_<MÔ_TẢ> (Viết HOA)
#   Ví dụ: ERROR_FILE_NOT_FOUND, PROMPT_ENTER_USERNAME, HELP_CACHE_CLEAN
# =============================================

# =============================================
# 🏠 Menu & Navigation
# =============================================
readonly TITLE_MENU_WELCOME="CHÀO MỪNG ĐẾN VỚI WP DOCKER"
readonly TITLE_MENU_MAIN="Menu chức năng chính"
readonly TITLE_MENU_WEBSITE="QUẢN LÝ WEBSITE"
readonly TITLE_MENU_SSL="QUẢN LÝ CHỨNG CHỈ SSL"
readonly TITLE_MENU_SYSTEM="CÔNG CỤ HỆ THỐNG"
readonly TITLE_MENU_RCLONE="QUẢN LÝ RCLONE"
readonly TITLE_MENU_WORDPRESS="Công cụ WordPress"
readonly TITLE_MENU_BACKUP="QUẢN LÝ BACKUP"
readonly TITLE_MENU_PHP="Quản lý PHP"
readonly TITLE_MENU_DATABASE="Quản lý Database"
readonly TITLE_WEBSITE_DELETE="XÓA WEBSITE KHỎI HỆ THỐNG"
readonly TITLE_CREATE_NEW_WORDPRESS_WEBSITE="TẠO WEBSITE WORDPRESS MỚI"
readonly TITLE_MENU_WESBITE_CREATE="TẠO MỚI WEBSITE"

readonly MSG_BACK="⬅️  Quay lại"
readonly MSG_EXIT="🚪 Thoát ra"
readonly MSG_EXITING="Đang thoát ra"
readonly MSG_SELECT_OPTION="🔹 Nhập số tùy chọn tương ứng trên menu: "
readonly MSG_PRESS_ENTER_CONTINUE="Enter để tiếp tục..."
readonly MSG_CLEANING_UP="Đang dọn dẹp"
readonly MSG_CREATED="Đã tạo"
readonly MSG_WEBSITE_EXIST="Website đã tồn tại"
readonly MSG_DOCKER_VOLUME_FOUND="Đã tìm thấy volume đang tồn tại"
readonly MSG_NOT_FOUND="Không tìm thấy"
readonly MSG_START_CONTAINER="Khởi động container"
readonly MSG_CHECKING_CONTAINER="Đang kiểm tra container..."
readonly MSG_CONTAINER_READY="Container đã sẵn sàng"
readonly MSG_WEBSITE_SELECTED="Đã chọn"
readonly MSG_WEBSITE_BACKUP_BEFORE_REMOVE="Đang tạo backup trước khi xóa..."
readonly MSG_WEBSITE_BACKING_UP_DB="Đang sao lưu database"
readonly MSG_WEBSITE_BACKING_UP_FILES="Đang sao lưu mã nguồn"
readonly MSG_WEBSITE_BACKUP_FILE_CREATED="Đã hoàn tất sao lưu và lưu trữ"
readonly MSG_WEBSITE_STOPPING_CONTAINERS="Dừng các container của website"
readonly MSG_NGINX_REMOVE_MOUNT="Gỡ cấu hình volume trong NGINX"
readonly MSG_WEBSITE_DELETING_DIRECTORY="Xóa thư mục website"
readonly MSG_WEBSITE_DELETING_SSL="Xóa chứng chỉ SSL của website"
readonly MSG_WEBSITE_DELETING_VOLUME="Xóa volume của database"
readonly MSG_WEBSITE_DELETING_NGINX_CONF="Xóa cấu hình NGINX của website"
readonly MSG_DOCKER_NGINX_RESTART="Khởi động lại NGINX"
readonly MSG_LATEST="mới nhất"

# =============================================
# 🐳 Docker & Container Management
# =============================================
readonly LABEL_DOCKER_STATUS="🐳 Trạng thái Docker"
readonly LABEL_DOCKER_NETWORK_STATUS="Trạng thái Docker Network"
readonly LABEL_DOCKER_NGINX_STATUS="Trạng thái NGINX Proxy"

readonly SUCCESS_DOCKER_STATUS="Docker đang hoạt động"
readonly SUCCESS_DOCKER_NETWORK_STATUS="Mạng Docker đang hoạt động"
readonly SUCCESS_DOCKER_NGINX_STATUS="NGINX Proxy đang hoạt động"
readonly SUCCESS_DOCKER_NGINX_RESTART="NGINX đã được khởi động lại hoàn tất"
readonly SUCCESS_DOCKER_NGINX_RELOAD="NGINX đã được nạp lại cấu hình"
readonly SUCCESS_DOCKER_NGINX_CREATE_DOCKER_COMPOSE_OVERRIDE="Tập tin docker-compose.override.yml đã được khởi tạo và cấu hình"
readonly SUCCESS_DOCKER_NGINX_MOUNT_VOLUME="Gắn tài nguyên thành công"
readonly SUCCESS_CONTAINER_STOP="Container đã được dừng và xóa"
readonly SUCCESS_CONTAINER_VOLUME_REMOVE="Volume đã được xóa"
readonly SUCCESS_DIRECTORY_REMOVE="Thư mục đã được xóa"
readonly SUCCESS_COPY="Đã sao chép thành công"
readonly SUCCESS_NGINX_CONF_CREATED="Đã tạo file cấu hình NGINX"
readonly SUCCESS_SSL_CERTIFICATE_REMOVED="Đã xóa chứng chỉ SSL"
readonly SUCCESS_FILE_REMOVED="Đã xóa tập tin"
readonly SUCCESS_CRON_REMOVED="Đã xóa cron liên quan của website"
readonly SUCCESS_WEBSITE_REMOVED="Đã xóa website hoàn tất"
readonly SUCCESS_WEBSITE_RESTART="Đã khởi động lại website hoàn tất"

readonly ERROR_DOCKER_STATUS="Docker không hoạt động"
readonly ERROR_DOCKER_NETWORK_STATUS="Mạng Docker không hoạt động"
readonly ERROR_DOCKER_NGINX_STATUS="NGINX Proxy không hoạt động"
readonly ERROR_DOCKER_NGINX_RESTART="NGINX khởi động lại thất bại."
readonly ERROR_DOCKER_NGINX_STOP="Tắt NGINX thất bại"
readonly ERROR_DOCKER_NGINX_START="NGINX bật lên thất bại"
readonly ERROR_DOCKER_NGINX_RELOAD="NGINX nạp lại cấu hình thất bại"
readonly ERROR_DOCKER_NGINX_MOUNT_VOLUME="Gắn tài nguyên thất bại"
readonly ERROR_DOCKER_DOWN="Có lỗi khi dừng container"
readonly ERROR_DOCKER_UP="Có lỗi khi khởi động container"
readonly ERROR_CONTAINER_NOT_READY_AFTER_30S="Container chưa sẵn sàng sau 30 giây. Hãy kiểm tra lại!"
readonly ERROR_NGINX_TEMPLATE_DIR_MISSING="Thư mục chứa file template NGINX không tồn tại"
readonly ERROR_NGINX_TEMPLATE_NOT_FOUND="Không tìm thấy file template NGINX"
readonly ERROR_TRAP_LOG="Lỗi xảy ra tại hàm "
readonly ERROR_BACKUP_FILE="Có lỗi khi sao lưu mã nguồn"

readonly INFO_DOCKER_NGINX_STARTING="NGINX đang được khởi động lại"
readonly INFO_DOCKER_NGINX_RELOADING="NGINX đang được nạp lại cấu hình"
readonly INFO_DOCKER_NGINX_CREATING_DOCKER_COMPOSE_OVERRIDE="Tập tin docker-compose.override.yml đang được khởi tạo"
readonly INFO_DOCKER_NGINX_MOUNT_NOCHANGE="Không tìm thấy thay đổi nào với các volume được gắn"

readonly WARNING_REMOVE_OLD_NGINX_CONF="Đang xoá cấu hình NGINX cũ"
readonly SKIP_DOCKER_NGINX_MOUNT_VOLUME_EXIST="Nguồn tài nguyên đã tồn tại"
readonly SUCCESS_DOCKER_NGINX_MOUNT_REMOVED="Đã xóa các volume được mount trên NGINX"

# =============================================
# 🌐 Website Management
# =============================================
readonly LABEL_MENU_WEBISTE_CREATE="Tạo website mới"
readonly LABEL_MENU_WEBSITE_DELETE="Xóa website"
readonly LABEL_MENU_WEBSITE_LIST="Danh sách website"
readonly LABEL_MENU_WEBSITE_RESTART="Khởi động lại website"
readonly LABEL_MENU_WEBSITE_LOGS="Xem log website"
readonly LABEL_MENU_WEBSITE_INFO="Xem thông tin website"
readonly LABEL_MENU_WEBSITE_UPDATE_TEMPLATE="Cập nhật template cấu hình"

readonly LABEL_WEBSITE_INFO="Thông tin website cho "
readonly LABEL_WEBSITE_DOMAIN="Tên miền"
readonly LABEL_WEBSITE_DB_NAME="Tên database"
readonly LABEL_WEBSITE_DB_USER="Database username"
readonly LABEL_WEBSITE_DB_PASS="Mật khẩu database"
readonly LABEL_SITE_DIR="Thư mục website"
readonly LABEL_WEBSITE_LIST="Danh sách website"

readonly PROMPT_ENTER_DOMAIN="Nhập tên miền website (vd: azdigi.com)"
readonly PROMPT_WEBSITE_CREATE_RANDOM_ADMIN="Bạn có muốn hệ thống tự tạo mật khẩu mạnh cho admin? [Y/n]:"
readonly PROMPT_BACKUP_BEFORE_DELETE="Bạn có muốn sao lưu dữ liệu website trước khi xóa? (NÊN LÀM)"
readonly PROMPT_WEBSITE_DELETE_CONFIRM="Bạn có chắc là muốn xóa website không?"
readonly PROMPT_WEBSITE_SELECT="🔹 Chọn một website: "

readonly ERROR_NO_WEBSITE_SELECTED="Không có website được chọn"
readonly ERROR_NO_WEBSITES_FOUND="Không có website nào"
readonly ERROR_NOT_EXIST="không tồn tại"
readonly ERROR_ENV_NOT_FOUND="Tập tin .env không tìm thấy"

readonly STEP_WEBSITE_SETUP_NGINX="Thiết lập NGINX"
readonly STEP_WEBSITE_SETUP_COPY_CONFIG="Sao chép cấu hình mẫu"
readonly STEP_WEBSITE_SETUP_APPLY_CONFIG="Tính toán cấu hình MariaDB & PHP tự động"
readonly STEP_WEBSITE_SETUP_CREATE_ENV="Tạo tập tin .env cho website"
readonly STEP_WEBSITE_SETUP_CREATE_SSL="Tạo chứng chỉ SSL tư ký cho website"
readonly STEP_WEBSITE_SETUP_CREATE_DOCKER_COMPOSE="Thiết lập docker-compose.yml cho website"
readonly STEP_WEBSITE_SETUP_WORDPRESS="Cài đặt WordPress"
readonly STEP_WEBSITE_SETUP_ESSENTIALS="Đang cấu hình cơ bản (permalinks, plugin bảo mật,...)"
readonly STEP_WEBSITE_RESTARTING="Đang khởi động lại website"

readonly MSG_WEBSITE_PERMISSIONS="Kiểm tra và thiết lập phân quyền"

# =============================================
# 📦 WordPress Installation & Management
# =============================================
readonly INFO_START_WP_INSTALL="Bắt đầu cài đặt WordPress cho"
readonly INFO_WAITING_PHP_CONTAINER="Đang chờ container PHP"
readonly INFO_DOWNLOADING_WP="Đang tải mã nguồn WordPress..."
readonly INFO_SITE_URL="🌐 Trang web"
readonly INFO_ADMIN_URL="👤 Trang quản trị"
readonly INFO_ADMIN_USER="👤 Tài khoản admin"
readonly INFO_ADMIN_PASSWORD="🔐 Mật khẩu admin"
readonly INFO_ADMIN_EMAIL="📧 Email admin"

readonly SUCCESS_WP_SOURCE_DOWNLOADED="Đã tải mã nguồn WordPress."
readonly SUCCESS_WP_SOURCE_EXISTS="Mã nguồn WordPress đã tồn tại."
readonly SUCCESS_WP_INSTALL_DONE="Cài đặt WordPress hoàn tất."

readonly ERROR_PHP_CONTAINER_NOT_READY="Container PHP không sẵn sàng sau 30s"
readonly ERROR_WP_INSTALL_FAILED="Cài đặt WordPress thất bại."
readonly ERROR_PERMISSION_SETTING="Không thể phân quyền thư mục."
readonly ERROR_WPCLI_INVALID_PARAMS="Bạn phải cung cấp lệnh WP-CLI để thực thi"

readonly WARNING_SKIP_CHOWN="Bỏ qua chown vì container PHP chưa sẵn sàng."
readonly WARNING_ADMIN_USERNAME_EMPTY="Username không được để trống."
readonly WARNING_ADMIN_PASSWORD_MISMATCH="Mật khẩu không khớp hoặc bị trống. Vui lòng nhập lại."

readonly PROMPT_WEBSITE_SETUP_WORDPRESS_USERNAME="👤 Nhập tên người dùng"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD="🔑 Nhập mật khẩu"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_PASSWORD_CONFIRM="🔑 Nhập lại mật khẩu"
readonly PROMPT_WEBSITE_SETUP_WORDPRESS_EMAIL="📫 Nhập địa chỉ email"

# =============================================
# 📊 System Information & Updates
# =============================================
readonly LABEL_SYSTEM_INFO="📊 Thông tin hệ thống:"
readonly LABEL_CPU="CPU"
readonly LABEL_RAM="RAM"
readonly LABEL_DISK="Ổ đĩa"
readonly LABEL_IPADDR="Địa chỉ IP"
readonly LABEL_VERSION_CHANNEL="📦 Kênh phiên bản"
readonly INFO_LABEL_CORE_VERSION="Phiên bản WP Docker"

readonly ERROR_VERSION_CHANNEL_INVALID_CHANNEL="Kênh phiên bản không hợp lệ"
readonly ERROR_CORE_VERSION_FAILED_FETCH="Lấy thông tin phiên bản trên Github thất bại!"

readonly PROGRESS_CORE_VERSION_FILE_OUTDATED="Đang lấy thông tin phiên bản mới nhất"

# =============================================
# 🏗️ Main Menu Options
# =============================================
readonly LABEL_MENU_MAIN_WEBSITE="Quản lý Website"
readonly LABEL_MENU_MAIN_SSL="Quản lý chứng chỉ SSL"
readonly LABEL_MENU_MAIN_SYSTEM="Công cụ hệ thống"
readonly LABEL_MENU_MAIN_RCLONE="Quản lý RClone"
readonly LABEL_MENU_MAIN_WORDPRESS="Công cụ WordPress"
readonly LABEL_MENU_MAIN_BACKUP="Quản lý Backup"
readonly LABEL_MENU_MAIN_WORDPRESS_CACHE="Thiết lập Cache WordPress"
readonly LABEL_MENU_MAIN_PHP="Quản lý PHP"
readonly LABEL_MENU_MAIN_DATABASE="Quản lý Database"
readonly LABEL_MENU_MAIN_UPDATE="Kiểm tra & Cập nhật WP Docker"

# =============================================
# 🔒 SSL Management
# =============================================
readonly LABEL_MENU_SSL_SELFSIGNED="Tạo chứng chỉ tự ký"
readonly LABEL_MENU_SSL_MANUAL="Cài chứng chỉ thủ công (trả phí)"
readonly LABEL_MENU_SSL_EDIT="Sửa chứng chỉ"
readonly LABEL_MENU_SSL_LETSENCRYPT="Cài chứng chỉ miễn phí từ Let's Encrypt"
readonly LABEL_MENU_SSL_CHECK="Kiểm tra thông tin chứng chỉ"

# =============================================
# 🛠️ System Tools
# =============================================
readonly LABEL_MENU_SYSTEM_CHECK="Kiểm tra tài nguyên"
readonly LABEL_MENU_SYSTEM_MANAGE_DOCKER="Quản lý container Docker"
readonly LABEL_MENU_SYSTEM_CLEANUP_DOCKER="Dọn dẹp Docker"
readonly LABEL_MENU_SYSTEM_REBUILD_NGINX="Rebuild lại container NGINX"

# =============================================
# ☁️ RClone Management
# =============================================
readonly LABEL_MENU_RCLONE_SETUP="Thiết lập storage Rclone"
readonly LABEL_MENU_RCLONE_UPLOAD_BACKUP="Upload backup lên cloud"
readonly LABEL_MENU_RCLONE_LIST_STORAGE="Xem danh sách storage cloud"
readonly LABEL_MENU_RCLONE_DELETE_STORAGE="Xóa storage cloud"
readonly LABEL_MENU_RCLONE_AVAILABLE_STORAGE="Danh sách storage đang khả dụng"

# =============================================
# 🔄 WordPress Tools
# =============================================
readonly LABEL_MENU_WORDPRESS_RESET_ADMPASSWD="Reset mật khẩu Admin"
readonly LABEL_MENU_WORDPRESS_EDIT_USER_ROLE="Reset quyền người dùng"
readonly LABEL_MENU_WORDPRESS_AUTO_UPDATE_PLUGIN="Bật/Tắt tự động cập nhật Plugin"
readonly LABEL_MENU_WORDPRESS_PROTECT_WPLOGIN="Bật/Tắt bảo vệ wp-login.php"
readonly LABEL_MENU_WORDPRESS_MIGRATION="Chuyển dữ liệu WordPress về WP Docker"

# =============================================
# 💾 Backup Management
# =============================================
readonly LABEL_MENU_BACKUP_NOW="Sao lưu website ngay"
readonly LABEL_MENU_BACKUP_MANAGE="Quản lý Backup"
readonly LABEL_MENU_BACKUP_SCHEDULE="Lên lịch backup tự động"
readonly LABEL_MENU_BACKUP_SCHEDULE_MANAGE="Quản lý lịch backup"
readonly LABEL_MENU_BACKUP_RESTORE="Khôi phục dữ liệu"
readonly MSG_BACKUP_LISTING="Hiển thị danh sách backup"
readonly LABEL_BACKUP_FILE_LIST="File Backup"
readonly LABEL_BACKUP_DB_LIST="Database Backup"
readonly STEP_CLEANING_OLD_BACKUPS="Đang dọn dẹp các bản backup cũ hơn %s ngày trong %s"
readonly SUCCESS_BACKUP_CLEAN="Đã dọn dẹp backup hoàn tất"
readonly ERROR_BACKUP_INVALID_ACTION="Hành động sai, hãy sử dụng hành động list hoặc clean"
readonly ERROR_BACKUP_RESTORE_FILE_MISSING_PARAMS="Thiếu tham số: Tập tin backup hoặc thư mục website không hợp lệ"
readonly MSG_BACKUP_RESTORING_FILE="Đang khôi phục mã nguồn từ %s đến %s"
readonly SUCCESS_BACKUP_RESTORED_FILE="Dã khôi phục mã nguồn thành công"
readonly ERROR_BACKUP_RESTORE_FAILED="Có lỗi xảy ra trong quá trình khôi phục dữ liệu"
readonly MSG_BACKUP_RESTORING_DB="Đang khôi phục dữ liệu từ %s vào %s"
readonly ERROR_BACKUP_RESTORE_DB_MISSING_PARAMS="Thiếu tham số: Dường dẫn backup, tên container hoặc tên miền website không hợp lệ"
readonly ERROR_BACKUP_FAILED_FETCH_DB_NAME_ENV="Không thể lấy tên database từ tập tin .env. Hãy kiểm tra lại tập tin này."
readonly ERROR_BACKUP_PASSWD_NOT_FOUND="Thiếu thông tin MYSQL_ROOT_PASSWORD trong .env hoặc bị sai. Không thể khôi phục database."
readonly ERROR_BACKUP_ENV_FILE_NOT_FOUND="Không tìm thấy tập tin .env tại"
readonly SUCCESS_BACKUP_RESTORED_DB="Đã hoàn tất khôi phục database"
readonly ERROR_DOCKER_CONTAINER_DB_NOT_RUNNING="Container database không hoạt động"
# =============================================
# 🐘 PHP Management
# =============================================
readonly LABEL_MENU_PHP_CHANGE="Thay đổi phiên bản PHP cho website"
readonly LABEL_MENU_PHP_REBUILD="Rebuild PHP container"
readonly LABEL_MENU_PHP_EDIT_CONF="Chỉnh sửa php-fpm.conf"
readonly LABEL_MENU_PHP_EDIT_INI="Chỉnh sửa php.ini"

readonly ERROR_PHP_LIST_EMPTY="Danh sách phiên bản đang bị trống. Hãy chạy lại lệnh bên dưới để cập nhật lại danh sách phiên bản PHP."
readonly MSG_PHP_LIST_SUPPORTED="Các phiên bản PHP được hỗ trợ (từ Bitnami): "
readonly WARNING_PHP_ARM_TITLE="Chú ý khi sử dụng trên máy ARM/Apple Silicon"
readonly WARNING_PHP_ARM_LINE1="Phiên bản PHP 8.0 trở xuống không hoạt động trên CPU kiến trúc ARM như:"
readonly WARNING_PHP_ARM_LINE2="Apple Silicon (M1, M2,...), Raspberry Pi, ARM64 server,..."
readonly WARNING_PHP_ARM_LINE3="Nếu bạn gặp lỗi \"platform mismath\" thì hãy thêm:"
readonly WARNING_PHP_ARM_LINE4="${STRONG}platform: linux/amd64${NC} vào tập tin docker-compose.yml trong thư mục website tại sites/domain.ltd/"
readonly WARNING_PHP_ARM_LINE5="Sau đó sử dụng lệnh wpdocker website restart --domain=domain.ltd để khởi động lại website"
readonly TIPS_PHP_RECOMMEND_VERSION="Khuyến khích sử dụng PHP từ 8.2 trở lên!"

# =============================================
# 💾 Database Management
# =============================================
readonly LABEL_MENU_DATABASE_RESET="Reset cơ sở dữ liệu (❗ NGUY HIỂM)"
readonly LABEL_MENU_DATABASE_EXPORT="Xuất dữ liệu database"
readonly LABEL_MENU_DATABASE_IMPORT="Nhập dữ liệu database"

# =============================================
# ⚠️ Error & Parameter Handling
# =============================================
readonly ERROR_UNKNOW_PARAM="Không nhận diện được tham số: "
readonly ERROR_MISSING_PARAM="Thiếu tham số"
readonly INFO_PARAM_EXAMPLE="Ví dụ tham số"
readonly ERROR_BACKUP_MANAGE_MISSING_PARAMS="Thiếu tham số. Hãy đảm bảo bạn đã có tham số --domain và --action."
readonly ERROR_SELECT_OPTION_INVALID="Tùy chọn không hợp lệ. Hãy nhập số tùy chọn tương ứng!"
readonly ERROR_COMMAND_FAILED="Thực thi lệnh thất bại"




readonly INFO_SELECT_BACKUP_SCHEDULE="Chọn lịch backup tự động:"
readonly INFO_SELECT_STORAGE_LOCATION="Chọn nơi lưu trữ backup:"
readonly LABEL_BACKUP_LOCAL="Lưu trên máy chủ (local)"
readonly LABEL_BACKUP_CLOUD="Lưu vào Storage đã cấu hình"
readonly PROMPT_SELECT_STORAGE_OPTION="Nhập số tương ứng với nơi lưu backup (1 = Local, 2 = Cloud):"
readonly INFO_RCLONE_READING_STORAGE_LIST="Đang đọc danh sách Storage từ rclone.conf..."
readonly WARNING_RCLONE_STORAGE_EMPTY="Chưa có Storage nào được cấu hình trong rclone.conf!"
readonly PROMPT_ENTER_STORAGE_NAME="Nhập tên Storage muốn sử dụng:"
readonly SUCCESS_RCLONE_STORAGE_SELECTED="Đã chọn Storage:"
readonly PROMPT_ENTER_CUSTOM_CRON="Nhập lịch backup theo cú pháp cron (vd: '30 2 * * *'):"
readonly SUCCESS_CRON_CREATED="Đã thiết lập lịch backup thành công!"
readonly WARNING_INPUT_INVALID="Tùy chọn không hợp lệ. Vui lòng thử lại!"



readonly LABEL_SUNDAY="Chủ nhật"
readonly LABEL_MONDAY="Thứ hai"
readonly LABEL_TUESDAY="Thứ ba"
readonly LABEL_WEDNESDAY="Thứ tư"
readonly LABEL_THURSDAY="Thứ năm"
readonly LABEL_FRIDAY="Thứ sáu"
readonly LABEL_SATURDAY="Thứ bảy"
readonly LABEL_EVERYDAY="Mỗi ngày"
readonly LABEL_EVERY_WEEK="Mỗi tuần"
readonly LABEL_EVERY_MONTH="Mỗi tháng"
readonly LABEL_EVERY_YEAR="Mỗi năm"
readonly LABEL_EVERY_HOUR="Mỗi giờ"
readonly LABEL_EVERY_MINUTE="Mỗi phút"
readonly LABEL_EVERY_5_MINUTES="Mỗi 5 phút"
readonly LABEL_EVERY_10_MINUTES="Mỗi 10 phút"
readonly LABEL_EVERY_15_MINUTES="Mỗi 15 phút"
readonly LABEL_EVERY_30_MINUTES="Mỗi 30 phút"
readonly LABEL_EVERY_1_HOUR="Mỗi 1 giờ"
readonly LABEL_EVERY_2_HOURS="Mỗi 2 giờ"
readonly LABEL_EVERY_3_HOURS="Mỗi 3 giờ"
readonly LABEL_EVERY_4_HOURS="Mỗi 4 giờ"
readonly LABEL_EVERY_6_HOURS="Mỗi 6 giờ"
readonly LABEL_EVERY_12_HOURS="Mỗi 12 giờ"
readonly LABEL_EVERY_24_HOURS="Mỗi 24 giờ"

readonly LABEL_FREQUENCY="Tần suất"
readonly LABEL_LOG_PATH="Đường dẫn log"

readonly WARNING_CORE_DEV_CACHE_OUTDATED="Bộ nhớ cache phiên bản dev đã quá hạn. Đang tải lại..."
readonly INFO_CORE_DEV_CACHE_MISSING="Không tìm thấy cache phiên bản dev. Đang tải..."
readonly ERROR_VERSION_CHANNEL_FILE_NOT_FOUND="Không tìm thấy tập tin version.txt"
readonly ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST="Lấy thông tin phiên bản mới nhất thất bại cho kênh: %s"
readonly INFO_CORE_CACHE_NOT_FOUND="Chưa có cache cho phiên bản chính. Đang tải về..."
readonly WARNING_CORE_CACHE_OUTDATED="Cache phiên bản chính đã cũ. Đang tải lại..."
readonly WARNING_CORE_CACHE_MISSING="Không có cache phiên bản. Đang lấy lần đầu từ Github..."
readonly WARNING_CORE_VERSION_NEW_AVAILABLE="🚀 Có phiên bản mới! Hiện tại: %s → Mới nhất: %s"
readonly TIP_CORE_UPDATE_COMMAND="Chạy lệnh: wpdocker core update để cập nhật hệ thống."
readonly INFO_CORE_VERSION_LATEST="Bạn đang sử dụng phiên bản mới nhất: %s"


readonly ERROR_CONFIG_SITES_DIR_NOT_SET="Biến SITES_DIR chưa được thiết lập. Hãy kiểm tra lại config.sh."
readonly WARNING_BACKUP_DIR_NOT_EXIST_CREATE="Thư mục lưu backup không tồn tại. Đang tạo: %s"
readonly ERROR_BACKUP_CREATE_DIR_FAILED="Không thể tạo thư mục lưu backup."
readonly ERROR_BACKUP_DB_DUMP_FAILED="Không thể thực hiện sao lưu database: %s"
readonly STEP_BACKUP_DATABASE="Đang sao lưu database: %s"

readonly QUESTION_DB_RESET_CONFIRM="Bạn có chắc chắn muốn RESET database '%s' cho website '%s'? Tất cả dữ liệu sẽ bị xóa!"
readonly CONFIRM_DB_RESET="Bạn có muốn tiếp tục? (y/n): "
readonly STEP_DB_RESETTING="Đang reset lại database '%s' cho website '%s'..."
readonly SUCCESS_DB_RESET_DONE="Đã reset database '%s' thành công."
readonly ERROR_DB_FETCH_CREDENTIALS="Không thể lấy thông tin database từ .env cho website '%s'."
readonly ERROR_DB_RESET_FAILED="Reset database '%s' thất bại."
readonly ERROR_PARAM_SITE_NAME_REQUIRED="Thiếu tham số tên website (--domain)"
readonly MSG_OPERATION_CANCELLED="Hành động đã bị huỷ."
readonly ERROR_PHP_VERSION_REQUIRED="Chưa cung cấp phiên bản PHP. Vui lòng nhập phiên bản PHP."
readonly STEP_PHP_UPDATING_ENV="Đang cập nhật phiên bản PHP trong file .env..."
readonly STEP_PHP_UPDATING_DOCKER_COMPOSE="Đang cập nhật phiên bản PHP trong docker-compose.yml..."
readonly SUCCESS_PHP_ENV_UPDATED="Đã cập nhật phiên bản PHP trong .env: %s"
readonly SUCCESS_PHP_DOCKER_COMPOSE_UPDATED="Đã cập nhật docker-compose.yml thành công với phiên bản PHP mới."
readonly WARNING_PHP_IMAGE_LINE_NOT_FOUND="Không tìm thấy dòng image để cập nhật. Vui lòng kiểm tra thủ công."
readonly ERROR_PHP_DOCKER_COMPOSE_NOT_FOUND="Không tìm thấy tập tin docker-compose.yml để cập nhật."
readonly STEP_PHP_RESTARTING="Đang khởi động lại container PHP để áp dụng thay đổi..."
readonly SUCCESS_PHP_CHANGED="Website '%s' hiện đang chạy với phiên bản PHP: %s"
readonly INFO_PHP_GETTING_LIST="Đang kiểm tra danh sách phiên bản PHP..."
readonly STEP_PHP_FETCHING_FROM_DOCKER="Đang tải dữ liệu từ Docker Hub..."
readonly SUCCESS_PHP_LIST_CACHED="Danh sách PHP đã có sẵn (dưới 7 ngày, dùng cache)"
readonly SUCCESS_PHP_LIST_SAVED="Đã lưu danh sách PHP vào: %s"
readonly WARNING_PHP_NOT_RUNNING="Container PHP không hoạt động. Bỏ qua bước dừng container."
readonly SUCCESS_CONTAINER_OLD_REMOVED="Đã xóa container PHP cũ (nếu có)"
readonly ERROR_PHP_REBUILD_FAILED="Không thể rebuild container PHP"
readonly ERROR_RCLONE_CONFIG_NOT_FOUND="Không tìm thấy tập tin cấu hình rclone.conf"
readonly WARNING_RCLONE_NO_STORAGE_CONFIGURED="Không có Storage nào được cấu hình trong rclone.conf"
readonly SUCCESS_RCLONE_STORAGE_REMOVED="Đã xóa Storage '%s' khỏi cấu hình"
readonly WARNING_RCLONE_NOT_INSTALLED="Rclone chưa được cài đặt. Đang tiến hành cài đặt..."
readonly ERROR_RCLONE_INSTALL_FAILED="Không thể cài đặt Rclone!"
readonly SUCCESS_RCLONE_INSTALLED="Đã cài đặt Rclone thành công!"
readonly SUCCESS_RCLONE_ALREADY_INSTALLED="Rclone đã được cài đặt."
readonly INFO_RCLONE_SETUP_START="Đang thiết lập Storage Rclone"
readonly INFO_RCLONE_CREATING_CONF="Đang tạo file cấu hình Rclone mới: %s"
readonly ERROR_RCLONE_CREATE_CONF_FAILED="Không thể tạo file: %s"
readonly ERROR_RCLONE_STORAGE_EXISTED="Storage '%s' đã tồn tại. Vui lòng nhập tên khác."
readonly INFO_RCLONE_SELECT_STORAGE_TYPE="Chọn loại storage bạn muốn thiết lập:"
readonly STEP_RCLONE_SETTING_UP="Đang thiết lập Storage: %s..."
readonly INFO_RCLONE_DRIVE_AUTH_GUIDE="Chạy lệnh: rclone authorize drive trên máy tính của bạn để lấy token OAuth."
readonly SUCCESS_RCLONE_DRIVE_SETUP="Đã thiết lập Google Drive thành công!"
readonly SUCCESS_RCLONE_STORAGE_ADDED="Đã thiết lập Storage %s thành công!"
readonly INFO_BACKUP_NO_FILES_PASSED="Không có tập tin nào được chỉ định."
readonly ERROR_ENV_DOMAIN_NOT_FOUND="Biến DOMAIN không tồn tại trong tập tin .env"
readonly ERROR_SSL_CERT_NOT_FOUND="Không tìm thấy file chứng chỉ: %s"
readonly INFO_SSL_CHECKING_FOR_DOMAIN="Đang kiểm tra chứng chỉ SSL của domain: %s"
readonly LABEL_SSL_DOMAIN="Tên miền"
readonly LABEL_SSL_ISSUER="Tổ chức cấp"
readonly LABEL_SSL_START_DATE="Hiệu lực từ"
readonly LABEL_SSL_END_DATE="Hết hạn vào"
readonly LABEL_SSL_STATUS="Trạng thái"
readonly ERROR_SSL_CERT_NOT_FOUND_FOR_DOMAIN="Không tìm thấy chứng chỉ SSL cho domain: %s"
readonly INFO_SSL_EDITING_FOR_DOMAIN="Đang chỉnh sửa chứng chỉ SSL cho website: %s"
readonly PROMPT_SSL_ENTER_NEW_CRT="Vui lòng dán nội dung mới của chứng chỉ SSL (*.crt) cho %s:"
readonly PROMPT_SSL_ENTER_NEW_KEY="Vui lòng dán nội dung mới của private key (*.key) cho %s:"
readonly SUCCESS_SSL_UPDATED_FOR_DOMAIN="Đã cập nhật chứng chỉ SSL thành công cho website: %s"
readonly INFO_SSL_RELOADING_NGINX="Đang nạp lại NGINX Proxy để áp dụng chứng chỉ mới..."
readonly SUCCESS_NGINX_RELOADED="NGINX Proxy đã được nạp lại thành công"
readonly INFO_RCLONE_UPLOAD_START="Bắt đầu tải lên bản sao lưu"
readonly INFO_RCLONE_UPLOAD_LIST="Danh sách tệp sẽ được tải lên:"
readonly INFO_RCLONE_UPLOADING="Đang tải lên tệp: %s"

readonly SUCCESS_RCLONE_UPLOAD_SINGLE="Tải lên thành công: %s"
readonly SUCCESS_RCLONE_UPLOAD_DONE="Hoàn tất việc tải lên bản sao lưu"

readonly ERROR_RCLONE_STORAGE_REQUIRED="Thiếu tham số tên storage cần thiết"
readonly ERROR_RCLONE_UPLOAD_FAILED_SINGLE="Tải lên thất bại: %s"
readonly ERROR_RCLONE_CANNOT_DETECT_SITE="Không thể xác định tên website từ đường dẫn tệp"
readonly ERROR_BACKUP_FOLDER_NOT_FOUND="Không tìm thấy thư mục backups"
readonly ERROR_BACKUP_NO_FILE_SELECTED="Không có tệp nào được chọn để tải lên"
readonly ERROR_BACKUP_FILE_NOT_FOUND="Không có tệp sao lưu nào trong thư mục này"

readonly PROMPT_SELECT_BACKUP_FILES="Chọn các tệp sao lưu để tải lên (dùng Spacebar để chọn, Enter để xác nhận):"
readonly ERROR_SITE_NOT_SELECTED="Chưa chọn website"
readonly ERROR_SITE_NOT_EXIST="Website '%s' không tồn tại"
readonly ERROR_SSL_SELF_SIGNED_GENERATE_FAILED="Không thể tạo chứng chỉ SSL tự ký"

readonly STEP_SSL_REGENERATE_SELF_SIGNED="Đang tạo lại chứng chỉ SSL tự ký cho website: %s"
readonly STEP_NGINX_RELOADING="Đang khởi động lại container nginx-proxy..."

readonly SUCCESS_SSL_SELF_SIGNED_GENERATED="Đã tạo lại chứng chỉ SSL tự ký thành công cho %s"

readonly INFO_SSL_CERT_PATH="Đường dẫn chứng chỉ SSL: %s"
readonly INFO_SSL_KEY_PATH="Đường dẫn khóa riêng SSL: %s"
readonly ERROR_DOMAIN_NOT_FOUND=".env không chứa biến DOMAIN"
readonly ERROR_WORDPRESS_DIR_NOT_FOUND="Không tìm thấy thư mục mã nguồn: %s"
readonly ERROR_CERTBOT_NOT_SUPPORTED_OS="Hệ điều hành không được hỗ trợ để cài certbot tự động"
readonly ERROR_CERTBOT_NOT_SUPPORTED_MAC="Việc cài đặt certbot tự động chỉ hỗ trợ Linux. Vui lòng cài thủ công trên macOS."
readonly ERROR_LE_CERTIFICATE_NOT_FOUND="Không tìm thấy chứng chỉ sau khi cấp phát. Vui lòng kiểm tra tên miền và cấu hình."
readonly ERROR_CERTBOT_NOT_INSTALLED="Certbot chưa được cài đặt. Đang tiến hành cài đặt..."
readonly SUCCESS_LE_CERTIFICATE_INSTALLED="Chứng chỉ Let's Encrypt đã được cấp phát thành công"
readonly SUCCESS_LE_INSTALLED="Let's Encrypt đã được cài đặt thành công cho website %s"
readonly INFO_LE_DOMAIN="Tên miền: %s"
readonly STEP_LE_REQUESTING_CERT="Đang gửi yêu cầu chứng chỉ Let's Encrypt với phương thức webroot..."
readonly SUCCESS_SSL_INSTALLED="Đã cài đặt chứng chỉ SSL thành công"
readonly STEP_REQUEST_CERT_WEBROOT="Đang yêu cầu chứng chỉ Let's Encrypt với phương thức webroot..."
readonly ERROR_CERTBOT_INSTALL_MAC="Không thể cài đặt certbot trên macOS. Vui lòng cài đặt thủ công."
readonly ERROR_CERTBOT_INSTALL_UNSUPPORTED_OS="Không thể cài đặt certbot trên hệ điều hành này. Vui lòng cài đặt thủ công."
readonly WARNING_CERTBOT_NOT_INSTALLED="Certbot chưa được cài đặt. Đang tiến hành cài đặt..."
readonly INFO_DOMAIN_SELECTED=:"Đã chọn tên miền"
readonly ERROR_SSL_FILE_EMPTY_OR_MISSING="Tập tin .crt hoặc .key bị thiếu hoặc rỗng"
readonly SUCCESS_SSL_MANUAL_SAVED="Chứng chỉ đã được cài đặt thủ công thành công"
readonly INFO_ENV_FILE_CONTENT="Nội dung tập tin .env:"
readonly TITLE_SYSTEM_RESOURCES="Tài nguyên hệ thống hiện tại"
readonly LABEL_TOTAL_RAM="Tổng RAM: %s"
readonly LABEL_DISK_USAGE="Sử dụng ổ đĩa: %s"
readonly LABEL_UPTIME="Thời gian hoạt động: %s"
readonly ERROR_DOCKER_NOT_INSTALLED="Docker chưa được cài đặt. Vui lòng cài đặt Docker trước."
readonly STEP_DOCKER_CLEANUP_START="Đang dọn dẹp các tài nguyên Docker không sử dụng..."
readonly STEP_DOCKER_REMOVE_UNUSED_NETWORKS="Đang xóa các mạng Docker không còn sử dụng..."
readonly SUCCESS_DOCKER_CLEANUP_DONE="Dọn dẹp Docker hoàn tất thành công."
readonly ERROR_CONTAINER_NAME_OR_ACTION_REQUIRED="Thiếu container hoặc hành động cần thực hiện."
readonly INFO_CONTAINER_LOG_STREAM="Đang xem log của container: %s"
readonly STEP_CONTAINER_RESTARTING="Đang khởi động lại container: %s"
readonly SUCCESS_CONTAINER_RESTARTED="Container '%s' đã được khởi động lại thành công."
readonly ERROR_CONTAINER_RESTART_FAILED="Không thể khởi động lại container: %s"
readonly ERROR_INVALID_ACTION_OPTION="Tùy chọn hành động không hợp lệ. Vui lòng chọn lại."
readonly STEP_NGINX_REBUILD_START="Đang rebuild lại container nginx-proxy..."

readonly ERROR_NGINX_STOP_REMOVE_FAILED="Không thể dừng và xóa container nginx-proxy."
readonly ERROR_NGINX_IMAGE_NAME_NOT_FOUND="Không tìm thấy tên image cho nginx-proxy trong docker-compose.yml."
readonly ERROR_NGINX_CONTAINER_START_FAILED="Không thể khởi động lại container nginx-proxy."

readonly SUCCESS_NGINX_CONTAINER_STARTED="Container nginx-proxy đã được khởi động lại thành công."
readonly ERROR_DB_IMPORT_FAILED="Lỗi khi khôi phục database từ tập tin: %s"
readonly ERROR_ENV_NOT_FOUND_FOR_SITE=".env không tồn tại cho website %s tại %s"
readonly ERROR_DB_ENV_MISSING="Không thể lấy thông tin database trong .env cho website: %s"
readonly ERROR_DB_CONTAINER_NOT_FOUND="Không tìm thấy CONTAINER_DB trong .env cho website: %s"
readonly STEP_DOCKER_INSTALL="Đang cài đặt Docker..."
readonly STEP_DOCKER_COMPOSE_INSTALL="Đang cài đặt Docker Compose plugin..."
readonly WARNING_DOCKER_NOT_RUNNING="Docker chưa chạy. Đang khởi động Docker..."
readonly SUCCESS_DOCKER_RUNNING="Docker đang chạy"
readonly INFO_DOCKER_REMOVING_CONTAINER="Đang xóa container: %s"
readonly INFO_DOCKER_REMOVING_VOLUME="Đang xóa volume: %s"
readonly ERROR_DOCKER_INSTALL_UNSUPPORTED_OS="Hệ điều hành của bạn không được hỗ trợ để cài đặt Docker tự động."
readonly ERROR_DOCKER_COMPOSE_INSTALL_FAILED="Cài đặt Docker Compose thất bại."
readonly ERROR_COMMAND_EXEC_FAILED="Đã xảy ra lỗi khi chạy lệnh: %s"
readonly ERROR_UNSUPPORTED_ARCH="Không hỗ trợ kiến trúc hệ thống: %s"
readonly INFO_DOCKER_GROUP_MAC="Trên macOS không cần thêm người dùng vào nhóm Docker."
readonly INFO_DOCKER_GROUP_ADDING="Đang thêm người dùng '%s' vào nhóm Docker..."
readonly SUCCESS_DOCKER_GROUP_ADDED="Đã thêm người dùng vào nhóm Docker. Vui lòng đăng xuất và đăng nhập lại để áp dụng."
readonly WARNING_REMOVE_CORE_CONTAINERS="Đang xóa các container chính: nginx-proxy và redis-cache"
readonly WARNING_REMOVE_SITE_CONTAINERS="Đang xóa các container cho website: %s"
readonly INFO_FILE_REMOVING="Đang xóa tập tin: %s"
readonly INFO_DIR_REMOVING="Đang xóa thư mục: %s"
readonly INFO_FILE_COPYING="Đang sao chép tập tin từ %s đến %s"
readonly INFO_DIR_CREATING="Đang tạo thư mục: %s"

readonly ERROR_FILE_SOURCE_NOT_FOUND="Không tìm thấy tập tin nguồn: %s"
readonly ERROR_DIRECTORY_NOT_FOUND="Không tìm thấy thư mục: %s"
readonly INFO_CREATE_DOCKER_NETWORK="Đang tạo Docker network: %s"
readonly SUCCESS_DOCKER_NETWORK_CREATED="Đã tạo Docker network '%s' thành công"
readonly SUCCESS_DOCKER_NETWORK_EXISTS="Docker network '%s' đã tồn tại"
readonly DEBUG_DOCKER_NETWORK_EXISTS="Docker network '%s' tồn tại"
readonly DEBUG_DOCKER_NETWORK_NOT_EXISTS="Docker network '%s' không tồn tại"

readonly DEBUG_PHP_FPM_CALCULATED="Giá trị PHP-FPM tối ưu dựa trên RAM=%sMB, CPU=%s: max_children=%s, start=%s, min_spare=%s, max_spare=%s"
readonly WARNING_PHP_FPM_REMOVE_DIR="Thư mục '%s' sẽ bị xoá vì cần tạo tập tin cấu hình mới"
readonly SUCCESS_PHP_FPM_CONFIG_CREATED="Đã tạo cấu hình PHP-FPM tối ưu tại: %s"
readonly INFO_CHECKING_EDITORS="Đang kiểm tra các trình soạn thảo văn bản khả dụng..."
readonly ERROR_NO_EDITOR_FOUND="Không tìm thấy trình soạn thảo nào! Vui lòng cài đặt nano hoặc vim."
readonly INFO_AVAILABLE_EDITORS="Danh sách trình soạn thảo khả dụng:"
readonly PROMPT_SELECT_EDITOR="Chọn số tương ứng với trình soạn thảo bạn muốn dùng:"
readonly WARNING_EDITOR_INVALID_SELECT="Lựa chọn không hợp lệ. Sẽ sử dụng mặc định là nano (nếu có)."
readonly INFO_EDITOR_USAGE_GUIDE="Hướng dẫn sử dụng trình soạn thảo: %s"
readonly PROMPT_CONFIRM_EDITOR="Bạn có muốn mở trình soạn thảo này để chỉnh sửa không?"
readonly WARNING_EDITOR_CANCELLED="Bạn đã huỷ thao tác chỉnh sửa."

readonly INFO_CHECKING_COMMANDS="Đang kiểm tra các lệnh yêu cầu..."
readonly WARNING_COMMAND_NOT_FOUND="Lệnh '%s' chưa được cài đặt. Đang tiến hành cài đặt..."
readonly ERROR_INSTALL_COMMAND_NOT_SUPPORTED="Không tìm thấy trình quản lý gói phù hợp để cài đặt '%s'."
readonly WARNING_HOMEBREW_MISSING="Homebrew chưa được cài đặt. Đang tiến hành cài đặt Homebrew..."
readonly ERROR_OS_NOT_SUPPORTED="Hệ điều hành không được hỗ trợ để cài đặt '%s'."
readonly SUCCESS_COMMAND_AVAILABLE="Lệnh '%s' đã được cài đặt và khả dụng."

readonly WARNING_TIMEZONE_NOT_VIETNAM="Múi giờ hệ thống chưa phải Asia/Ho_Chi_Minh. Đang thiết lập lại..."
readonly SUCCESS_TIMEZONE_SET="Múi giờ hệ thống đã được thiết lập về Asia/Ho_Chi_Minh."
readonly INFO_WP_CONFIGURING="Đang cấu hình tập tin wp-config.php trong container..."
readonly SUCCESS_WP_CONFIG_DONE="Tập tin wp-config.php đã được cấu hình thành công"
readonly ERROR_WP_CONFIG_FAILED="Không thể cấu hình wp-config.php"

readonly INFO_WP_INSTALLING="Đang cài đặt WordPress..."
readonly SUCCESS_WP_INSTALLED="WordPress đã được cài đặt thành công"

readonly ERROR_WP_PERMALINK_FAILED="Thiết lập đường dẫn tĩnh thất bại"

readonly ERROR_WP_SECURITY_PLUGIN="Cài đặt plugin bảo mật thất bại"
readonly SUCCESS_WP_SECURITY_PLUGIN="Plugin bảo mật đã được cài đặt và kích hoạt"

readonly ERROR_WP_PERFORMANCE_PLUGIN="Cài đặt plugin hiệu suất thất bại"
readonly SUCCESS_WP_PERFORMANCE_PLUGIN="Plugin hiệu suất đã được cài đặt và kích hoạt"

readonly INFO_WPCLI_CURRENT="Phiên bản WP-CLI hiện tại: v%s"
readonly INFO_WPCLI_UPDATING="Đang kiểm tra và cập nhật WP-CLI..."
readonly SUCCESS_WPCLI_UPDATED="WP-CLI đã được cập nhật lên phiên bản: v%s"
readonly PROMPT_SELECT_CHANNEL="Vui lòng chọn kênh phát hành để sử dụng:"
readonly PROMPT_SELECT_OPTION="Chọn tuỳ chọn: "
readonly SUCCESS_CORE_CHANNEL_SET="CORE_CHANNEL đã được thiết lập thành '%s' tại %s."
readonly WARNING_ENV_NOT_FOUND="Không tìm thấy tệp .env. Đang tạo mới..."
readonly SUCCESS_DOCKER_INSTALLED="Docker đã được cài đặt."
readonly SUCCESS_DOCKER_COMPOSE_INSTALLED="Docker Compose đã được cài đặt."
readonly SUCCESS_CRON_PHP_VERSION_SET="Đã thêm cron job để kiểm tra phiên bản PHP hàng ngày lúc 2 giờ sáng."
readonly WARNING_CRON_PHP_VERSION_EXISTS="Cron job cho php_get_version.sh đã tồn tại."
readonly WARNING_WPCLI_NOT_FOUND="WP-CLI chưa được cài đặt. Đang tiến hành cài đặt..."
readonly ERROR_WPCLI_DOWNLOAD_FAILED="Tải WP-CLI thất bại."
readonly ERROR_WPCLI_MOVE_FAILED="Di chuyển tập tin wp-cli.phar thất bại."
readonly SUCCESS_WPCLI_INSTALLED="Đã cài đặt WP-CLI thành công."
readonly SUCCESS_WPCLI_EXISTS="WP-CLI đã tồn tại tại %s."
readonly INFO_NGINX_PROXY_STARTING="Container nginx-proxy chưa khởi động. Đang khởi động..."
readonly INFO_NGINX_PROXY_WAIT="Đang kiểm tra trạng thái container nginx-proxy..."
readonly SUCCESS_NGINX_PROXY_RUNNING="Container nginx-proxy đang chạy."
readonly ERROR_NGINX_PROXY_NOT_RUNNING="Container nginx-proxy KHÔNG chạy được."
readonly ERROR_NGINX_PROXY_START_FAILED="Không thể khởi động nginx-proxy bằng docker compose."
readonly ERROR_NGINX_PROXY_LOG_HINT="Vui lòng kiểm tra cấu hình, volume hoặc cổng đang sử dụng."
readonly SUCCESS_SYSTEM_READY="Hệ thống đã sẵn sàng để sử dụng WP Docker LEMP."
readonly ERROR_DOCKER_CONTAINER_DB_NOT_DEFINED="Không tìm thấy tên container database trong .env. Vui lòng kiểm tra lại."
readonly TITLE_BACKUP_UPLOAD="UPLOAD BACKUP LÊN CLOUD"
readonly PROMPT_RCLONE_STORAGE_NAME="Nhập tên Storage Rclone bạn muốn upload: "
readonly ERROR_BACKUP_FOLDER_NOT_FOUND_FOR_SITE="Không tìm thấy tập tin backup cho website %s"
readonly LABEL_MENU_BACKUP_UPLOAD="Upload backup lên cloud (Rclone)"
readonly PROMPT_CHOOSE_ACTION_FOR_SITE="📋 Chọn hành động cho website '%s':"
readonly LABEL_ENABLE_AUTO_UPDATE_PLUGIN="Bật tự động cập nhật plugin"
readonly LABEL_DISABLE_AUTO_UPDATE_PLUGIN="Tắt tự động cập nhật plugin"
readonly PROMPT_ENTER_OPTION="Nhập số tương ứng với hành động:"
readonly ERROR_SITE_NOT_SELECTED="Bạn chưa chọn website nào."
readonly TITLE_MIGRATION_TOOL="🌐 WordPress Migration Tool"
readonly WARNING_MIGRATION_PREPARE="Vui lòng chuẩn bị các tệp nguồn trước khi tiếp tục:"
readonly TIP_MIGRATION_FOLDER_PATH="Tạo một thư mục theo tên domain tại:"
readonly TIP_MIGRATION_FOLDER_CONTENT="Trong thư mục đó, đặt các tệp sau:"
readonly TIP_MIGRATION_SOURCE="Một file .zip hoặc .tar.gz chứa mã nguồn website"
readonly TIP_MIGRATION_SQL="Một file .sql chứa dữ liệu database"
readonly QUESTION_MIGRATION_READY="Bạn đã chuẩn bị xong thư mục và các tệp chưa? (y/n):"
readonly ERROR_MIGRATION_CANCEL="Đã huỷ quá trình migrate. Vui lòng chuẩn bị đầy đủ trước."
readonly PROMPT_ENTER_DOMAIN_TO_MIGRATE="👉 Nhập tên domain để migrate:"
readonly ERROR_DOMAIN_REQUIRED="Bạn cần nhập tên domain."
readonly INFO_MIGRATION_STARTING="⚙️ Đang bắt đầu quá trình migrate cho '%s'..."
readonly ERROR_NO_WEBSITE_SELECTED="Bạn chưa chọn website nào."
readonly QUESTION_PROTECT_WPLOGIN_ACTION="Bạn muốn thực hiện hành động nào cho website '%s'?"
readonly LABEL_PROTECT_WPLOGIN_ENABLE="Bật bảo vệ trang wp-login.php"
readonly LABEL_PROTECT_WPLOGIN_DISABLE="Tắt bảo vệ trang wp-login.php"
readonly PROMPT_ENTER_ACTION_NUMBER="Nhập số tương ứng với hành động:"
readonly ERROR_INVALID_CHOICE="Lựa chọn không hợp lệ."
readonly ERROR_NO_WEBSITE_SELECTED="Bạn chưa chọn website nào."
readonly QUESTION_PROTECT_WPLOGIN_ACTION="Bạn muốn thực hiện hành động nào cho website '%s'?"
readonly LABEL_PROTECT_WPLOGIN_ENABLE="Bật bảo vệ trang wp-login.php"
readonly LABEL_PROTECT_WPLOGIN_DISABLE="Tắt bảo vệ trang wp-login.php"
readonly PROMPT_ENTER_ACTION_NUMBER="Nhập số tương ứng với hành động:"
readonly ERROR_INVALID_CHOICE="Lựa chọn không hợp lệ."
readonly ERROR_NO_WEBSITE_SELECTED="Bạn chưa chọn website nào."
readonly INFO_WORDPRESS_LIST_ADMINS="📋 Danh sách tài khoản Admin:"
readonly PROMPT_ENTER_ADMIN_USER_ID="👉 Nhập ID của tài khoản cần đặt lại mật khẩu:"
readonly ERROR_INPUT_REQUIRED="Giá trị không được để trống."
readonly WARNING_RESET_ADMIN_ROLE_1="Tính năng này sẽ thiết lập lại quyền Administrator về mặc định."
readonly WARNING_RESET_ADMIN_ROLE_2="Dùng trong trường hợp tài khoản Admin bị mất quyền hoặc không truy cập được."
readonly INFO_LIST_WEBSITES_RESET="📋 Danh sách website có thể reset quyền Admin:"
readonly ERROR_NO_WEBSITE_SELECTED="Bạn chưa chọn website nào."
readonly IMPORTANT_RESET_DATABASE_TITLE="CẢNH BÁO QUAN TRỌNG"
readonly ERROR_RESET_DATABASE_WARNING="Việc reset database sẽ xóa toàn bộ dữ liệu và không thể khôi phục!"
readonly WARNING_BACKUP_BEFORE_CONTINUE="📌 Vui lòng sao lưu đầy đủ trước khi tiếp tục."
readonly INFO_LIST_WEBSITES_FOR_DB_RESET="📋 Danh sách các website có thể reset database:"
readonly CONFIRM_RESET_DATABASE_FOR_SITE="Bạn có chắc chắn muốn reset database cho website '%s'?"
readonly CONFIRM_YES_RESET_DATABASE="Yes, reset database"
readonly CONFIRM_NO_CANCEL="NO"
readonly WARNING_RESET_DATABASE_CANCELLED="Thao tác reset database đã bị hủy."
readonly SUCCESS_DATABASE_RESET_DONE="Đã reset thành công database cho website '%s'."
readonly SUCCESS_PLUGIN_AUTO_UPDATE_ENABLED="Đã bật tự động cập nhật plugin cho website '%s'."
readonly SUCCESS_PLUGIN_AUTO_UPDATE_DISABLED="Đã tắt tự động cập nhật plugin cho website '%s'."
readonly INFO_PLUGIN_STATUS="📋 Trạng thái plugin hiện tại trên '%s':"
readonly PROMPT_WEBSITE_CREATE_CONFIRM="Bạn có muốn tạo website '%s' trước khi thực hiện migrate?"
readonly ERROR_FILE_NOT_FOUND="Không tìm thấy file: %s"
readonly ERROR_DOMAIN_NOT_POINT_TO_SERVER="Domain '%s' KHÔNG trỏ về server IP: %s. Vui lòng cập nhật DNS."
readonly SUCCESS_DOMAIN_POINTS_TO_IP="Domain '%s' đã trỏ về đúng IP: %s"
readonly SUCCESS_MIGRATION_DONE="Đã hoàn tất quá trình migrate cho '%s'."
readonly QUESTION_INSTALL_SSL="Bạn có muốn cài chứng chỉ SSL miễn phí từ Let's Encrypt ngay bây giờ không?"
readonly WARNING_TABLE_PREFIX_MISMATCH="table_prefix không khớp: DB='%s' | wp-config='%s'. Đang cập nhật..."
readonly INFO_INSTALLING_SSL="Đang cài đặt SSL cho %s..."
readonly INFO_SKIP_SSL_INSTALL="Bỏ qua bước cài SSL."
readonly TIP_MIGRATION_COMPLETE_USE_CACHE="Hãy chạy 'wpdocker' và chọn mục 'Thiết lập Cache WordPress' để tối ưu hiệu suất."
readonly STEP_WORDPRESS_UPDATE_CONFIG_DB="Cập nhật cấu hình database vào wp-config.php"
readonly SUCCESS_WORDPRESS_UPDATE_PREFIX="Đã cập nhật tiền tố (prefix) thành công."
readonly STEP_WORDPRESS_CHECK_DB_PREFIX="Kiểm tra tiền tố trong database"
readonly STEP_SSL_LETSENCRYPT="Cài đặt chứng chỉ SSL miễn phí từ Let's Encrypt"
readonly STEP_WEBSITE_CHECK_DNS="Kiểm tra trỏ tên miền"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_CONF_FILE="Tạo file cấu hình bảo vệ wp-login.php"
readonly STEP_WORDPRESS_PROTECT_WP_INCLUDE_NGINX="Đang thiết lập NGINX để bảo vệ wp-login.php"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_CREATE_DIR="Tạo thư mục chứa file cấu hình bảo vệ wp-login.php"
readonly IMPORTANT_WORDPRESS_PROTECT_WP_LOGIN_INSTALLED="wp-login.php đã được bảo vệ, hãy lưu các thông tin bên dưới để đăng nhập:"
readonly STEP_WORDPRESS_PROTECT_WP_LOGIN_DISABLE="Tắt bảo vệ wp-login.php"
