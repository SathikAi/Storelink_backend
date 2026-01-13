#!/bin/bash

set -e

BACKUP_DIR="/var/backups/storelink"
DATE=$(date +"%Y%m%d_%H%M%S")
DB_NAME="storelink_production"
DB_USER="storelink_user"
DB_PASSWORD="${MYSQL_PASSWORD}"
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

echo "Starting database backup at $(date)"

BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"

mysqldump \
    --user="$DB_USER" \
    --password="$DB_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --compress \
    "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "Backup completed successfully: $BACKUP_FILE"
    
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "Backup size: $BACKUP_SIZE"
    
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete
    echo "Old backups (older than $RETENTION_DAYS days) removed"
    
    BACKUP_COUNT=$(find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" | wc -l)
    echo "Total backups retained: $BACKUP_COUNT"
    
    if [ ! -z "$S3_BUCKET" ]; then
        echo "Uploading to S3..."
        aws s3 cp "$BACKUP_FILE" "s3://$S3_BUCKET/backups/database/" --storage-class STANDARD_IA
        if [ $? -eq 0 ]; then
            echo "Backup uploaded to S3 successfully"
        else
            echo "Failed to upload backup to S3"
        fi
    fi
else
    echo "Backup failed!"
    exit 1
fi

echo "Backup process completed at $(date)"
