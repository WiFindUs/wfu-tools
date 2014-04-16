#!/bin/bash
#===============================================================
# File: wfu-update.sh
# Author: Mark Gillard
# Target environment: Raspbian
# Description:
#   Re-clones, rebuilds and re-links local wfu tools.
#===============================================================
cd "$SRC_DIR"

echo -e "${STYLE_HEADING}Updating WFU-tools...${STYLE_NONE}"

echo -e "  ${STYLE_HEADING}cloning...${STYLE_NONE}"
sudo rm -f -r wfu-tools
git clone --depth 1 -q $WFU_REPOSITORY
cd wfu-tools
sudo rm -f rebuild-rpi-servald.sh
sudo rm -f rebuild-rpi-kernel.sh

echo -e "  ${STYLE_HEADING}deleting git artefacts...${STYLE_NONE}"
sudo rm -rf .git
sudo rm -f .gitattributes
sudo rm -f .gitignore

echo -e "  ${STYLE_HEADING}making wfu-setup...${STYLE_NONE}"
make -s -k

echo -e "  ${STYLE_HEADING}recreating symlinks...${STYLE_NONE}"
sudo chmod 755 *.sh
sudo chmod 755 wfu-setup

sudo rm -f /usr/bin/wfu-initial-setup
sudo ln -s "$WFU_TOOLS_DIR/wfu-initial-setup.sh" /usr/bin/wfu-initial-setup

sudo rm -f /usr/bin/wfu-purge-system
sudo ln -s "$WFU_TOOLS_DIR/wfu-purge-system.sh" /usr/bin/wfu-purge-system

sudo rm -f /usr/bin/wfu-update-system
sudo ln -s "$WFU_TOOLS_DIR/wfu-update-system.sh" /usr/bin/wfu-update-system

sudo rm -f /usr/bin/wfu-update
sudo ln -s "$WFU_TOOLS_DIR/wfu-update.sh" /usr/bin/wfu-update

sudo rm -f /usr/bin/wfu-remove-all
sudo ln -s "$WFU_TOOLS_DIR/wfu-remove-all.sh" /usr/bin/wfu-remove-all

sudo rm -f /usr/bin/wfu-preimage-purge
sudo ln -s "$WFU_TOOLS_DIR/wfu-preimage-purge.sh" /usr/bin/wfu-preimage-purge

sudo rm -f /usr/bin/wfu-setup
sudo ln -s "$WFU_TOOLS_DIR/wfu-setup" /usr/bin/wfu-setup

echo -e "  ${STYLE_SUCCESS}done!${STYLE_NONE}\n"
