#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup_database.sh"

chmod +x "$BACKUP_SCRIPT"

CRON_JOB="0 2 * * * $BACKUP_SCRIPT >> /var/log/storelink/backup.log 2>&1"

(crontab -l 2>/dev/null | grep -v "$BACKUP_SCRIPT"; echo "$CRON_JOB") | crontab -

echo "Cron job configured successfully!"
echo "Database backups will run daily at 2:00 AM"
echo ""
echo "Current crontab:"
crontab -l
