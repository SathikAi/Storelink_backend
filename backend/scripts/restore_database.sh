#!/bin/bash

set -e

BACKUP_DIR="/var/backups/storelink"
DB_NAME="storelink_production"
DB_USER="storelink_user"
DB_PASSWORD="${MYSQL_PASSWORD}"

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backups found in $BACKUP_DIR"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "WARNING: This will restore the database to the state in $BACKUP_FILE"
echo "Current database will be overwritten!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

echo "Starting database restore at $(date)"

echo "Creating backup of current database before restore..."
SAFETY_BACKUP="$BACKUP_DIR/${DB_NAME}_pre_restore_$(date +"%Y%m%d_%H%M%S").sql.gz"
mysqldump \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --single-transaction \
    "$DB_NAME" | gzip > "$SAFETY_BACKUP"

echo "Safety backup created: $SAFETY_BACKUP"

echo "Restoring from $BACKUP_FILE..."
gunzip < "$BACKUP_FILE" | mysql \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    "$DB_NAME"

if [ $? -eq 0 ]; then
    echo "Database restored successfully at $(date)"
    echo "Safety backup available at: $SAFETY_BACKUP"
else
    echo "Restore failed!"
    exit 1
fi
