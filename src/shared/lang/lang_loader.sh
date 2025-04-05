# ✅ Prevent multiple loading of language files
[[ -n "$LANG_LOADED" ]] && return
LANG_LOADED=true

LANG_FILE="$PROJECT_DIR/shared/lang/${LANG_CODE}.sh"

if [[ -f "$LANG_FILE" ]]; then
  source "$LANG_FILE"
else
  echo "⚠️ Language file not found: $LANG_FILE. Falling back to Vietnamese."
  source "$PROJECT_DIR/shared/lang/vi.sh"
fi