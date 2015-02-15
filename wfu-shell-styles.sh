#! /bin/bash
#===============================================================
# File: wfu-shell-styles.sh
# Author: Mark Gillard
# Description:
#   Pretty colours.
#===============================================================
# text color codes
#			fore	back
# Black		30		40
# Red		31		41
# Green		32		42
# Yellow	33		43
# Blue		34		44
# Magenta	35		45
# Cyan		36		46
# White		37		47

# text attribute codes
# 0	restore default color
# 1 brighter
# 2 dimmer
# 4	underlined text
# 5 flashing text
# 7 reverse video 

# text tagging syntax:
# ${STYLE_MARKER}<attribute>[;foreground][;<background>]m

STYLE_MARKER="\033["

#none - reset to console default
STYLE_NONE="${STYLE_MARKER}0m"

#title - bold white text on a blue background
STYLE_TITLE="${STYLE_MARKER}1;37;44m"

#heading - bold cyan text
STYLE_HEADING="${STYLE_MARKER}1;36m"

#input entry prompt - bright white text
STYLE_PROMPT="${STYLE_MARKER}4;37m"

#info text - gray text
STYLE_INFO="${STYLE_MARKER}1;37m"

#error text - bright red text
STYLE_ERROR="${STYLE_MARKER}1;31m"

#warning text - bright yellow text
STYLE_WARNING="${STYLE_MARKER}1;33m"

#success text - bright green text
STYLE_SUCCESS="${STYLE_MARKER}1;32m"

export STYLE_MARKER
export STYLE_NONE
export STYLE_TITLE
export STYLE_HEADING
export STYLE_PROMPT
export STYLE_INFO
export STYLE_ERROR
export STYLE_WARNING
export STYLE_SUCCESS
