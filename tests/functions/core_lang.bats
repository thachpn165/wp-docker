#!/usr/bin/env bats
load "../helpers/general.bash"
# =============================================
# 🔤 Test: core_lang_convert
# =============================================
@test "core_lang_convert returns correct label for known codes" {
  load ../helpers/load_lang_labels

  run core_lang_convert "vi"
  [ "$status" -eq 0 ]
  [ "$output" = "$LABEL_LANG_VI" ]

  run core_lang_convert "en"
  [ "$status" -eq 0 ]
  [ "$output" = "$LABEL_LANG_EN" ]

  run core_lang_convert "fr"
  [ "$status" -eq 0 ]
  [ "$output" = "$LABEL_LANG_FR" ]
}

@test "core_lang_convert returns Unknown for unsupported codes" {
  run core_lang_convert "xx"
  [ "$status" -eq 0 ]
  [ "$output" = "Unknown" ]
}

# =============================================
# 🌐 Test: core_lang_change_logic
# =============================================
@test "core_lang_change_logic updates valid language code" {
  export LANG_LIST=("vi" "en" "fr")
  run core_lang_change_logic "en"
  [ "$status" -eq 0 ]
}

@test "core_lang_change_logic fails with invalid code" {
  export LANG_LIST=("vi" "en")
  run core_lang_change_logic "jp"
  [ "$status" -ne 0 ]
}

# =============================================
# 🧪 Test: core_lang_get_logic
# =============================================
@test "core_lang_get_logic returns correct label" {
  json_set_value ".core.lang" "vi"
  run core_lang_get_logic
  
  # In ra output để kiểm tra
  echo "Output: $output"
  
  # Kiểm tra status code
  [ "$status" -eq 0 ]
  
  # Kiểm tra xem output có chứa $LABEL_LANG_VI không
  [[ "$output" == *"$LABEL_LANG_VI"* ]]
}

@test "core_lang_get_logic fails if lang not set" {
  json_set_value ".core.lang" ""
  run core_lang_get_logic
  # In ra output để kiểm tra
  echo "Output: $output"
  [ "$output" = "Unknown" ] #Unknown tương ứng với lang_code không hợp lệ
  [ "$status" -eq 0 ]
}
