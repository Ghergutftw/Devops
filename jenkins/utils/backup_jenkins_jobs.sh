#!/bin/bash

# Path to Jenkins jobs
JENKINS_HOME="/var/lib/jenkins"
JOBS_DIR="$JENKINS_HOME/jobs"

# Backup destination
BACKUP_DIR="/var/jenkins_job_configs_backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DEST="$BACKUP_DIR/$TIMESTAMP"

# Create the destination folder
mkdir -p "$DEST"

# Copy each job's config.xml into the backup folder
for job in "$JOBS_DIR"/*; do
    if [ -d "$job" ] && [ -f "$job/config.xml" ]; then
        JOB_NAME=$(basename "$job")
        mkdir -p "$DEST/$JOB_NAME"
        cp "$job/config.xml" "$DEST/$JOB_NAME/"
    fi
done

# Zip the backup folder
cd "$BACKUP_DIR"
zip -r "${TIMESTAMP}.zip" "$TIMESTAMP"

echo "Backup complete."
echo "Zipped file: $BACKUP_DIR/${TIMESTAMP}.zip"
