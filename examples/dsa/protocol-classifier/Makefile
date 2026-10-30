# Build a RouterOS DSA ABI v1 example plugin.
#
# Host build:
#   make CC=cc
#
# OpenWrt x86-64 cross build:
#   make clean
#   make CC=x86_64-openwrt-linux-musl-gcc \
#     ABI_INCLUDE=/path/to/os/custom-feed/router-dsa-sdk/files/include
#
# SPDX-License-Identifier: GPL-2.0-only

ROOT_DIR := $(abspath ../../..)
ABI_INCLUDE ?= $(ROOT_DIR)/custom-feed/router-dsa-sdk/files/include
CC ?= cc
CFLAGS ?= -O2
TARGET := protocol-classifier.so
SOURCE := protocol-classifier.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SOURCE) $(ABI_INCLUDE)/router-os/dsa.h
	$(CC) $(CFLAGS) -std=c11 -Wall -Wextra -Werror -fPIC -shared \
		-I$(ABI_INCLUDE) -o $@ $(SOURCE)

clean:
	rm -f $(TARGET)
