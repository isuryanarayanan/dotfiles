#!/bin/bash

# Specify the backup directory
backup_dir="$(dirname "$0")/tmux_backup"

# Create the backup directory if it doesn't exist
mkdir -p "$backup_dir"

# Backup the tmux configuration files
cp -r ~/.tmux.conf "$backup_dir"
cp -r ~/.tmux "$backup_dir"

echo "Tmux files backed up successfully to $backup_dir"

