#!/bin/sh
# test/test.sh
set -e

echo "Testing plugin functionality..."

# Install plugin locally
mise plugin install mise-emacs .

# Test basic functionality
if [[ "$(mise ls-remote mise-emacs)" == "" ]]; then
    echo "ERROR: No versions available"
    exit 1
fi

# Test installation
mise install mise-emacs@latest

# Test execution
mise exec mise-emacs:tool -- --version

# Clean up
mise plugin remove mise-emacs

echo "All tests passed!"
