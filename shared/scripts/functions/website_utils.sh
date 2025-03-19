# Hiển thị danh sách website để chọn
select_website() {
    local sites=($(ls -d $SITES_DIR/*/ | xargs -n 1 basename))
    if [[ ${#sites[@]} -eq 0 ]]; then
        echo "❌ Không tìm thấy website nào trong $SITES_DIR"
        return 1
    fi

    echo "🔹 Chọn một website:"
    select SITE_NAME in "${sites[@]}"; do
        if [[ -n "$SITE_NAME" ]]; then
            echo "✅ Đã chọn: $SITE_NAME"
            break
        else
            echo "❌ Lựa chọn không hợp lệ!"
        fi
    done
}