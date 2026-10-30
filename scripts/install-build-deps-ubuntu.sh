#!/bin/sh
# Install the host packages needed to build OpenWrt on Ubuntu/WSL2.

set -eu

if [ "$(id -u)" -eq 0 ]; then
	SUDO=
else
	command -v sudo >/dev/null 2>&1 || {
		echo "Please run as root or install sudo." >&2
		exit 1
	}
	SUDO=sudo
fi

$SUDO apt-get update
$SUDO apt-get install -y \
	build-essential clang flex bison g++ gawk gcc-multilib \
	g++-multilib gettext git libncurses-dev libssl-dev python3 \
	python3-setuptools rsync swig unzip zlib1g-dev file wget curl zstd
