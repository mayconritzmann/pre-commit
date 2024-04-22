#!/bin/bash

# Function to add an asdf plugin
add_asdf_plugin() {
    local plugin_with_version="$1"
    local plugin_name=$(echo "$plugin_with_version" | awk '{print $1}')
    echo "Adding $plugin_name plugin..."
    asdf plugin add "$plugin_name" || { echo "Failed to add $plugin_name plugin"; exit 1; }
}

# Function to install an asdf plugin version
install_asdf_plugin_version() {
    local plugin_name="$1"
    local version="$2"
    echo "Installing $plugin_name $version..."
    asdf install "$plugin_name" "$version" || { echo "Failed to install $plugin_name $version"; exit 1; }
}

# Function to set the global version for an asdf plugin
set_asdf_plugin_global_version() {
    local plugin_name="$1"
    local version="$2"
    echo "Setting global version for $plugin_name to $version..."
    asdf global "$plugin_name" "$version" || { echo "Failed to set global version for $plugin_name"; exit 1; }
}

# Main function to add plugins, install versions locally, and set global versions
main() {
    local tool_versions=".tool-versions"
    if [[ ! -f "$tool_versions" ]]; then
        echo "Error: .tool-versions file not found"
        exit 1
    fi

    while read -r plugin version || [[ -n "$plugin" ]]; do
        add_asdf_plugin "$plugin"
        install_asdf_plugin_version "$plugin" "$version"
        set_asdf_plugin_global_version "$plugin" "$version"
    done < "$tool_versions"
}

# Execute main function
main
