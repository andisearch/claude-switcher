#!/bin/bash

# AI Runner ASCII Banner
# Universal prompt interpreter for AI coding agents

# ANSI Color Codes - Andi AI Blue Theme
# Based on Andi branding: Dodger Blue #3B75FA, Hawkes Blue #D0DFFC, Malibu #7AA4FC
BLUE='\033[1;34m'      # Bright Blue for border
CYAN='\033[1;36m'      # Bright Cyan for main text
DBLUE='\033[0;34m'     # Regular Blue for tagline
RESET='\033[0m'        # Reset color

show_banner() {
    # All banner output goes to stderr to keep stdout clean for piping
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    echo "" >&2
    echo -e "${CYAN}    █████╗ ██╗    ██████╗ ██╗   ██╗███╗   ██╗${RESET}" >&2
    echo -e "${CYAN}   ██╔══██╗██║    ██╔══██╗██║   ██║████╗  ██║${RESET}" >&2
    echo -e "${CYAN}   ███████║██║    ██████╔╝██║   ██║██╔██╗ ██║${RESET}" >&2
    echo -e "${CYAN}   ██╔══██║██║    ██╔══██╗██║   ██║██║╚██╗██║${RESET}" >&2
    echo -e "${CYAN}   ██║  ██║██║    ██║  ██║╚██████╔╝██║ ╚████║${RESET}" >&2
    echo -e "${CYAN}   ╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝${RESET}" >&2
    echo "" >&2
    echo -e "${DBLUE}          Brought to you by Andi AI${RESET}" >&2
    echo "" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}" >&2
    echo "" >&2
}
