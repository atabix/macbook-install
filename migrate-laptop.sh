#!/bin/bash
set -e

source_array=(
    "$HOME/.aws-gate"
    "$HOME/.aws"
    "$HOME/.oci"
    "$HOME/.ssh"
    "$HOME/.composer"
    "$HOME/.npmrc"
    "$HOME/Library/Application Support/Code/User"
    "$HOME/Library/Application Support/com.fournova.Tower3"
    "$HOME/Library/Application Support/com.raycast.macos"
    "$HOME/Library/Application Support/com.tinyapp.TablePlus"
    "$HOME/Library/Application Support/Firefox"
    "$HOME/Library/Application Support/Google"
)

copy_array=()

for item in "${source_array[@]}"; do
    if [ -d "$item" ]; then
        echo "Found $item, adding to migration."
        copy_array+=("$item")
    fi
done

tar cf migrate.tar "${copy_array[@]}"
