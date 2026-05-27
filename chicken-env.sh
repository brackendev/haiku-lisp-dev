#!/bin/sh
# Chicken Scheme environment fix for Haiku
# Source this before using chicken-install or csi.
# Used by every Chicken example in this repository, not specific to SDL2.
#
# Usage from repo root: . chicken-env.sh
# Usage from examples/<name>/: . ../../chicken-env.sh

export PATH="/bin:/boot/system/bin:$PATH"
export CHICKEN_REPOSITORY_PATH=/boot/system/lib/chicken/11:~/chicken-eggs/lib/chicken/11
export CHICKEN_EGG_CACHE=~/chicken-cache
export CHICKEN_INSTALL_PREFIX=~/chicken-eggs
export C_INCLUDE_PATH=/boot/system/develop/headers/chicken

mkdir -p ~/chicken-eggs/lib/chicken/11 ~/chicken-cache

echo "Chicken environment configured."
echo "Install eggs with: chicken-install <egg-name>"
