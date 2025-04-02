#!/bin/bash

# =====================================
# 🔄 Upgrade Script for v1.1.4-beta
# =====================================

echo "🛠 Running upgrade script for v1.1.4-beta..."

# ========================
# 🧐 Check and remove existing wp-docker symlink
# ========================
WPDOCKER_SYMLINK="/usr/local/bin/wpdocker"

if [[ -L "$WPDOCKER_SYMLINK" ]]; then
    echo "⚠️ Found existing symlink for wpdocker at $WPDOCKER_SYMLINK."
    echo "❌ Removing the existing symlink to avoid conflict with new alias functionality..."

    # Remove the symlink
    rm -f "$WPDOCKER_SYMLINK"

    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully removed the old wpdocker symlink."
    else
        echo "❌ Failed to remove the wpdocker symlink. Please check manually."
        exit 1
    fi
else
    echo "✅ No existing wpdocker symlink found. Proceeding with the upgrade..."
fi

# ========================
# 💡 Additional upgrade tasks
# ========================
echo "📦 Proceeding with other upgrade tasks..."
# Add additional upgrade steps here if necessary, such as migrations or config changes

echo "🎉 Upgrade to v1.1.4-beta completed successfully!"