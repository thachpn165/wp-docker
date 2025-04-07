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

readonly ERROR_VERSION_CHANNEL_FILE_NOT_FOUND="Không tìm thấy tập tin version.txt"
readonly ERROR_VERSION_CHANNEL_INVALID_CHANNEL="Kênh phiên bản không hợp lệ"
readonly ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST="Lấy thông tin phiên bản mới nhất thất bại!"
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
readonly ERROR_VERSION_CHANNEL_INVALID_CHANNEL="Kênh phiên bản không hợp lệ: %s"
readonly ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST="Lấy thông tin phiên bản mới nhất thất bại cho kênh: %s"
readonly INFO_CORE_CACHE_NOT_FOUND="Chưa có cache cho phiên bản chính. Đang tải về..."
readonly WARNING_CORE_CACHE_OUTDATED="Cache phiên bản chính đã cũ. Đang tải lại..."
readonly WARNING_CORE_CACHE_OUTDATED="Cache phiên bản hiện tại đã cũ. Đang lấy lại từ Github..."
readonly WARNING_CORE_CACHE_MISSING="Không có cache phiên bản. Đang lấy lần đầu từ Github..."
readonly WARNING_CORE_VERSION_NEW_AVAILABLE="🚀 Có phiên bản mới! Hiện tại: %s → Mới nhất: %s"
readonly TIP_CORE_UPDATE_COMMAND="Chạy lệnh: wpdocker core update để cập nhật hệ thống."
readonly INFO_CORE_VERSION_LATEST="Bạn đang sử dụng phiên bản mới nhất: %s"


readonly ERROR_CONFIG_SITES_DIR_NOT_SET="Biến SITES_DIR chưa được thiết lập. Hãy kiểm tra lại config.sh."
readonly ERROR_PARAM_SITE_NAME_REQUIRED="Thiếu tham số tên website."
readonly WARNING_BACKUP_DIR_NOT_EXIST_CREATE="Thư mục lưu backup không tồn tại. Đang tạo: %s"
readonly ERROR_BACKUP_CREATE_DIR_FAILED="Không thể tạo thư mục lưu backup."
readonly ERROR_DB_FETCH_CREDENTIALS="Không thể lấy thông tin kết nối database cho website: %s"
readonly ERROR_BACKUP_DB_DUMP_FAILED="Không thể thực hiện sao lưu database: %s"
readonly STEP_BACKUP_DATABASE="Đang sao lưu database: %s"

readonly ERROR_CONFIG_SITES_DIR_NOT_SET="Biến SITES_DIR chưa được thiết lập. Hãy kiểm tra lại cấu hình."
readonly ERROR_PARAM_SITE_NAME_REQUIRED="Thiếu tên website (domain)."
readonly ERROR_DB_FETCH_CREDENTIALS="Không thể lấy thông tin database cho website: %s"
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