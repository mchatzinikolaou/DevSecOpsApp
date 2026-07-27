#!/bin/bash
# Install git hooks into the local repository

HOOKS_DIR=".git/hooks"
SOURCE_DIR="git-hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

echo "Installing git hooks..."

# Copy hooks
cp "$SOURCE_DIR/pre-commit" "$HOOKS_DIR/pre-commit" 2>/dev/null
cp "$SOURCE_DIR/pre-push" "$HOOKS_DIR/pre-push" 2>/dev/null

# Make executable
chmod +x "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-push"

echo "Git hooks installed successfully"
exit 0