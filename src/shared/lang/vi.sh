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
readonly MSG_BACK="⬅️  Quay lại"
readonly MSG_EXIT="🚪 Thoát ra"
readonly MSG_EXITING="Đang thoát ra"
readonly MSG_SELECT_OPTION="🔹 Nhập số tùy chọn tương ứng trên menu: "
readonly MSG_PRESS_ENTER_CONTINUE="Enter để tiếp tục..."

# =============================================
# 🐳 Docker Status
# =============================================
readonly LABEL_DOCKER_STATUS="🐳 Trạng thái Docker"
readonly LABEL_DOCKER_NETWORK_STATUS="Trạng thái Docker Network"
readonly LABEL_DOCKER_NGINX_STATUS="Trạng thái NGINX Proxy"
readonly SUCCESS_DOCKER_STATUS="Docker đang hoạt động"
readonly ERROR_DOCKER_STATUS="Docker không hoạt động"
readonly SUCCESS_DOCKER_NETWORK_STATUS="Mạng Docker đang hoạt động"
readonly ERROR_DOCKER_NETWORK_STATUS="Mạng Docker không hoạt động"
readonly SUCCESS_DOCKER_NGINX_STATUS="NGINX Proxy đang hoạt động"
readonly ERROR_DOCKER_NGINX_STATUS="NGINX Proxy không hoạt động"

# =============================================
# 📊 System Information
# =============================================
readonly LABEL_SYSTEM_INFO="📊 Thông tin hệ thống:"
readonly LABEL_CPU="CPU"
readonly LABEL_RAM="RAM"
readonly LABEL_DISK="Ổ đĩa"
readonly LABEL_IPADDR="Địa chỉ IP"

# =============================================
# 📦 Version & Updates
# =============================================
readonly LABEL_VERSION_CHANNEL="📦 Kênh phiên bản"
readonly ERROR_VERSION_CHANNEL_FILE_NOT_FOUND="Không tìm thấy tập tin version.txt"
readonly ERROR_VERSION_CHANNEL_INVALID_CHANNEL="Kênh phiên bản không hợp lệ"
readonly ERROR_VERSION_CHANNEL_FAILED_FETCH_LATEST="Lấy thông tin phiên bản mới nhất thất bại!"
readonly INFO_LABEL_CORE_VERSION="Phiên bản WP Docker"
readonly MSG_LATEST="mới nhất"
readonly PROGRESS_CORE_VERSION_FILE_OUTDATED="Đang lấy thông tin phiên bản mới nhất"
readonly ERROR_CORE_VERSION_FAILED_FETCH="Lấy thông tin phiên bản trên Github thất bại!"

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
# 🌐 Website Management
# =============================================
readonly LABEL_MENU_WEBISTE_CREATE="Tạo website mới"
readonly LABEL_MENU_WEBSITE_DELETE="Xóa website"
readonly LABEL_MENU_WEBSITE_LIST="Danh sách website"
readonly LABEL_MENU_WEBSITE_RESTART="Khởi động lại website"
readonly LABEL_MENU_WEBSITE_LOGS="Xem log website"
readonly LABEL_MENU_WEBSITE_INFO="Xem thông tin website"
readonly LABEL_MENU_WEBSITE_UPDATE_TEMPLATE="Cập nhật template cấu hình"

# =============================================
# ⚠️ Error Messages
# =============================================
readonly ERROR_SELECT_OPTION_INVALID="Tùy chọn không hợp lệ. Hãy nhập số tùy chọn tương ứng!"




readonly TITLE_MENU_SSL="QUẢN LÝ CHỨNG CHỈ SSL"
readonly LABEL_MENU_SSL_SELFSIGNED="Tạo chứng chỉ tự ký"
readonly LABEL_MENU_SSL_MANUAL="Cài chứng chỉ thủ công (trả phí)"
readonly LABEL_MENU_SSL_EDIT="Sửa chứng chỉ"
readonly LABEL_MENU_SSL_LETSENCRYPT="Cài chứng chỉ miễn phí từ Let's Encrypt"
readonly LABEL_MENU_SSL_CHECK="Kiểm tra thông tin chứng chỉ"



readonly TITLE_MENU_SYSTEM="CÔNG CỤ HỆ THỐNG"
readonly LABEL_MENU_SYSTEM_CHECK="Kiểm tra tài nguyên"
readonly LABEL_MENU_SYSTEM_MANAGE_DOCKER="Quản lý container Docker"
readonly LABEL_MENU_SYSTEM_CLEANUP_DOCKER="Dọn dẹp Docker"
readonly LABEL_MENU_SYSTEM_REBUILD_NGINX="Rebuild lại container NGINX"

readonly TITLE_MENU_RCLONE="QUẢN LÝ RCLONE"
readonly LABEL_MENU_RCLONE_SETUP="Thiết lập storage Rclone"
readonly LABEL_MENU_RCLONE_UPLOAD_BACKUP="Upload backup lên cloud"
readonly LABEL_MENU_RCLONE_LIST_STORAGE="Xem danh sách storage cloud"
readonly LABEL_MENU_RCLONE_DELETE_STORAGE="Xóa storage cloud"
readonly LABEL_MENU_RCLONE_AVAILABLE_STORAGE="Danh sách storage đang khả dụng"

readonly TITLE_MENU_WORDPRESS="Công cụ WordPress"
readonly LABEL_MENU_WORDPRESS_RESET_ADMPASSWD="Reset mật khẩu Admin"
readonly LABEL_MENU_WORDPRESS_EDIT_USER_ROLE="Reset quyền người dùng"
readonly LABEL_MENU_WORDPRESS_AUTO_UPDATE_PLUGIN="Bật/Tắt tự động cập nhật Plugin"
readonly LABEL_MENU_WORDPRESS_PROTECT_WPLOGIN="Bật/Tắt bảo vệ wp-login.php"
readonly LABEL_MENU_WORDPRESS_MIGRATION="Chuyển dữ liệu WordPress về WP Docker"

readonly TITLE_MENU_BACKUP="QUẢN LÝ BACKUP"
readonly LABEL_MENU_BACKUP_NOW="Sao lưu website ngay"
readonly LABEL_MENU_BACKUP_MANAGE="Quản lý Backup"
readonly LABEL_MENU_BACKUP_SCHEDULE="Lên lịch backup tự động"
readonly LABEL_MENU_BACKUP_SCHEDULE_MANAGE="Quản lý lịch backup"
readonly LABEL_MENU_BACKUP_RESTORE="Khôi phục dữ liệu"

readonly TITLE_MENU_PHP="Quản lý PHP"
readonly LABEL_MENU_PHP_CHANGE="Thay đổi phiên bản PHP cho website"
readonly LABEL_MENU_PHP_REBUILD="Rebuild PHP container"
readonly LABEL_MENU_PHP_EDIT_CONF="Chỉnh sửa php-fpm.conf"
readonly LABEL_MENU_PHP_EDIT_INI="Chỉnh sửa php.ini"

readonly TITLE_MENU_DATABASE="Quản lý Database"
readonly LABEL_MENU_DATABASE_RESET="Reset cơ sở dữ liệu (❗ NGUY HIỂM)"
readonly LABEL_MENU_DATABASE_EXPORT="Xuất dữ liệu database"
readonly LABEL_MENU_DATABASE_IMPORT="Nhập dữ liệu database"
