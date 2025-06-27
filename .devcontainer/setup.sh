#!/bin/bash

# Setup script for the Draft Dev Container
# This script runs after the container is created

echo "Setting up Draft Dev Container..."

# Run the setup command
bin/setup --skip-server

# Create SSH directory and add GitHub to known hosts
mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

echo "Setup complete!" 