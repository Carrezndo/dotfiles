#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +"%Y-%m-%d_%H-%M-%S")"

alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

echo "=== Dotfiles Checkout with Auto-Backup ==="

mkdir -p "$BACKUP_DIR"

echo "Checking out dotfiles..."

if dot checkout 2> /tmp/dotfiles-errors.log; then
  echo "Dotfiles checked out cleanly."
else
  echo "Conflicts detected. Backing up existing files..."

  grep -E "^\s+" /tmp/dotfiles-errors.log | awk '{print $1}' | while read -r file; do
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    mv "$HOME/$file" "$BACKUP_DIR/$file"
    echo "Backed up: $file"
  done

  echo "Retrying checkout..."
  dot checkout
fi

rm -f /tmp/dotfiles-errors.log

dot config --local status.showUntrackedFiles no

echo ""
echo "Dotfiles installed successfully."
echo "Backup location:"
echo "  $BACKUP_DIR"
