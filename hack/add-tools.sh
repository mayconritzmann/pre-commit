#!/bin/bash

set -x

# Function to add an asdf plugin (skip if already added)
add_asdf_plugin() {
    local plugin_with_version="$1"
    local plugin_name=$(echo "$plugin_with_version" | awk '{print $1}')

    # Check if plugin is already added
    if asdf plugin list | grep -q "^${plugin_name}$"; then
        echo "Plugin $plugin_name is already installed, skipping..."
        return 0
    fi

    echo "Adding $plugin_name plugin..."
    asdf plugin add "$plugin_name" || { echo "Failed to add $plugin_name plugin"; exit 1; }
}

# Function to check if a specific version is installed
is_version_installed() {
    local plugin_name="$1"
    local version="$2"
    asdf list "$plugin_name" 2>/dev/null | grep -q "^  ${version}$"
}

# Function to install an asdf plugin version (skip if already installed)
install_asdf_plugin_version() {
    local plugin_name="$1"
    local version="$2"

    # Check if version is already installed
    if is_version_installed "$plugin_name" "$version"; then
        echo "$plugin_name $version is already installed, skipping..."
        return 0
    fi

    echo "Installing $plugin_name $version..."
    asdf install "$plugin_name" "$version" || { echo "Failed to install $plugin_name $version"; exit 1; }
}

# Function to set the global version for an asdf plugin
# asdf 0.16+ (Go) uses "asdf set -u" instead of "asdf global"
set_asdf_plugin_global_version() {
    local plugin_name="$1"
    local version="$2"
    echo "Setting global version for $plugin_name to $version..."
    local original_dir=$(pwd)
    cd ~ || { echo "Failed to change to home directory"; exit 1; }
    asdf set -u "$plugin_name" "$version" || {
        cd "$original_dir"
        echo "Failed to set global version for $plugin_name";
        exit 1;
    }
    cd "$original_dir"
}

# Main function to add plugins, install versions locally, and set global versions
main() {
    local tool_versions="${1:-.tool-versions}"

    if [[ ! -f "$tool_versions" ]]; then
        echo "Warning: .tool-versions file not found at $tool_versions, skipping tool installation"
        return 0
    fi

    echo "Processing .tool-versions file: $tool_versions"

    # Skip empty lines and comments
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Extract plugin name and version
        local plugin=$(echo "$line" | awk '{print $1}')
        local version=$(echo "$line" | awk '{print $2}')

        # Skip if plugin or version is empty
        [[ -z "$plugin" || -z "$version" ]] && continue

        echo "Processing: $plugin $version"
        add_asdf_plugin "$plugin $version"
        install_asdf_plugin_version "$plugin" "$version"
        set_asdf_plugin_global_version "$plugin" "$version"
    done < "$tool_versions"

    # Reshim to ensure all tools are available
    asdf reshim
}

# Execute main function
main
