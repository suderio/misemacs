#!/bin/sh

# Link for development
mise plugin link mise-emacs /path/to/plugin

# Test all functionality
mise ls-remote mise-emacs
mise install mise-emacs@latest
mise use mise-emacs@latest

# Test in different environments
docker run --rm -it ubuntu:latest bash -c "
    curl -fsSL https://mise.en.dev/install.sh | sh
    mise plugin install mise-emacs https://github.com/suderio/mise-emacs
    mise install mise-emacs@latest
"
