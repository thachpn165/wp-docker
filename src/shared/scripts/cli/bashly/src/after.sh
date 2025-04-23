# check if DEBUG_MODE=true
if [[ "$DEBUG_MODE" == "true" ]]; then
    inspect_args
    return 0
fi
