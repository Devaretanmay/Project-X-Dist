#!/bin/bash
# ─────────────────────────────────────────────────────────
#  Blackwall Runtime Security — Installer
#  Usage: curl -sSL https://raw.githubusercontent.com/Devaretanmay/Project-X/master/install.sh | sh
# ─────────────────────────────────────────────────────────

set -euo pipefail

REPO="Devaretanmay/Project-X-Dist"
BINARY_NAME="blackwall"
INSTALL_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

echo ""
echo -e "${BLUE}${BOLD}  ██████╗ ██╗      █████╗  ██████╗██╗  ██╗██╗    ██╗ █████╗ ██╗     ██╗${RESET}"
echo -e "${BLUE}  ██╔══██╗██║     ██╔══██╗██╔════╝██║ ██╔╝██║    ██║██╔══██╗██║     ██║${RESET}"
echo -e "${BLUE}  ██████╔╝██║     ███████║██║     █████╔╝ ██║ █╗ ██║███████║██║     ██║${RESET}"
echo -e "${BLUE}  ██╔══██╗██║     ██╔══██║██║     ██╔═██╗ ██║███╗██║██╔══██║██║     ██║${RESET}"
echo -e "${BLUE}  ██████╔╝███████╗██║  ██║╚██████╗██║  ██╗╚███╔███╔╝██║  ██║███████╗███████╗${RESET}"
echo ""
echo -e "${DIM}  Runtime Security — Installer${RESET}"
echo ""

# ─── Detect platform ─────────────────────────────────────

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    darwin) PLATFORM="apple-darwin" ;;
    linux)  PLATFORM="unknown-linux-gnu" ;;
    *)
        echo -e "${RED}✗ Unsupported OS: $OS${RESET}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64)  ARCH="x86_64" ;;
    arm64)   ARCH="aarch64" ;;
    aarch64) ARCH="aarch64" ;;
    *)
        echo -e "${RED}✗ Unsupported architecture: $ARCH${RESET}"
        exit 1
        ;;
esac

TARGET="${ARCH}-${PLATFORM}"
# GitHub Release Asset Name Format: blackwall-v1.2.3-x86_64-apple-darwin.tar.gz or similar
# For simplicity, we'll assume the binary itself is uploaded as blackwall-${TARGET}
# or a tarball. Let's aim for a binary download for simplicity first, or tarball if preferred.
# Given standard rust release actions, it's often a tarball. Let's support direct binary for now suitable for the workflow we will build.

ASSET_NAME="blackwall-${TARGET}"

echo -e "  ${DIM}Platform: ${TARGET}${RESET}"

# ─── Download ─────────────────────────────────────────────

DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/${ASSET_NAME}"

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

echo -e "  ${DIM}Downloading from: ${DOWNLOAD_URL}${RESET}"
echo ""

AUTH_HEADER=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
    AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
fi

if command -v curl &>/dev/null; then
    if [ -n "$AUTH_HEADER" ]; then
        curl -H "$AUTH_HEADER" -H "Accept: application/octet-stream" -fsSL "$DOWNLOAD_URL" -o "$TMPFILE" || {
            echo -e "${RED}✗ Download failed (404/403). Check your GITHUB_TOKEN.${RESET}"
            exit 1
        }
    else
        curl -fsSL "$DOWNLOAD_URL" -o "$TMPFILE" || {
            echo -e "${RED}✗ Download failed. For private repos, ensure GITHUB_TOKEN is exported.${RESET}"
            exit 1
        }
    fi
elif command -v wget &>/dev/null; then
    if [ -n "$AUTH_HEADER" ]; then
        wget --header="$AUTH_HEADER" --header="Accept: application/octet-stream" -q "$DOWNLOAD_URL" -O "$TMPFILE" || {
            echo -e "${RED}✗ Download failed.${RESET}"
            exit 1
        }
    else
        wget -q "$DOWNLOAD_URL" -O "$TMPFILE" || {
            echo -e "${RED}✗ Download failed.${RESET}"
            exit 1
        }
    fi
else
    echo -e "${RED}✗ Neither curl nor wget found. Please install one.${RESET}"
    exit 1
fi

# ─── Install ──────────────────────────────────────────────

chmod +x "$TMPFILE"

echo -e "  ${DIM}Installing to ${INSTALL_DIR}...${RESET}"

if [ -w "$INSTALL_DIR" ]; then
    mv "$TMPFILE" "${INSTALL_DIR}/${BINARY_NAME}"
else
    echo -e "  ${DIM}Requires sudo to write to ${INSTALL_DIR}${RESET}"
    sudo mv "$TMPFILE" "${INSTALL_DIR}/${BINARY_NAME}"
fi

# ─── Verify ──────────────────────────────────────────────

if command -v "$BINARY_NAME" &>/dev/null; then
    echo ""
    echo -e "${GREEN}${BOLD}  ✓ Blackwall installed successfully${RESET}"
    echo ""
    echo -e "  ${DIM}Binary:${RESET}  ${INSTALL_DIR}/${BINARY_NAME}"
    echo -e "  ${DIM}Version:${RESET} $(${BINARY_NAME} --version 2>/dev/null || echo 'unknown')"
    echo ""
    echo -e "  Run ${BOLD}${BINARY_NAME}${RESET} to start."
    echo ""
else
    echo ""
    echo -e "${RED}✗ Installation could not be verified.${RESET}"
    echo -e "  ${DIM}Ensure ${INSTALL_DIR} is in your PATH.${RESET}"
    exit 1
fi
