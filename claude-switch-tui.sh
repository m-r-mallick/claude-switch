#!/bin/bash

# Claude Switch - Beautiful TUI for Claude Model Configuration Management
# Install: curl -fsSL <url> | bash

set -e

VERSION="1.1.0"
INSTALL_URL="https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/claude-switch/install"
REPO_URL="https://github.com/YOUR_USER/YOUR_REPO"

# Default configs (used if no ~/.claudeswitchrc exists)
declare -A DEFAULT_CONFIGS
DEFAULT_CONFIGS[mimo]='{
  "base_url": "https://api.xiaomimimo.com/anthropic",
  "auth_token": "sk-skblimkkjzpdn2pkk3sm9cjrfxvwk2r2copxs6mnk8lm9gjq",
  "opus_model": "mimo-v2-flash",
  "sonnet_model": "mimo-v2-flash",
  "haiku_model": "mimo-v2-flash"
}'
DEFAULT_CONFIGS[anthropic]='{
  "base_url": "https://api.anthropic.com/v1",
  "auth_token": "YOUR_ANTHROPIC_API_KEY",
  "opus_model": "claude-3-opus-20240229",
  "sonnet_model": "claude-3-5-sonnet-20241022",
  "haiku_model": "claude-3-haiku-20240307"
}'
DEFAULT_CONFIGS[minimax]='{
  "base_url": "https://api.minimax.io/anthropic",
  "auth_token": "sk-cp-QUthXmZyhdn029sRkSI6_A5k7gyflRU0pdcvmcxToEZmmF0T3Z-BYgAuFztllLToHeT87iO9JI5Ap_aWOSjCWqHHvELNOHGxahVM2a5vPjG-m1TsU4L1TzU",
  "opus_model": "MiniMax-M2.1",
  "sonnet_model": "MiniMax-M2.1",
  "haiku_model": "MiniMax-M2.1"
}'

# File paths
CONFIG_FILE="$HOME/.claudeswitchrc"
SETTINGS_FILE="$HOME/.claude/settings.json"
BINARY_PATH="/usr/local/bin/claude-switch"

# Colors
readonly NC='\033[0m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'

# ============================================
# Config File Management (~/.claudeswitchrc)
# ============================================

init_config_file() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        local init_json='{}'
        for name in "${!DEFAULT_CONFIGS[@]}"; do
            init_json=$(echo "$init_json" | jq --arg n "$name" --argjson v "${DEFAULT_CONFIGS[$name]}" '. + {($n): $v}')
        done
        echo "$init_json" > "$CONFIG_FILE"
    fi
}

load_configs() {
    init_config_file
    cat "$CONFIG_FILE"
}

get_config() {
    local name="$1"
    init_config_file
    cat "$CONFIG_FILE" | jq -r ".[\"$name\"] // empty"
}

save_config() {
    local name="$1"
    local config_json="$2"
    init_config_file

    local escaped_config=$(echo "$config_json" | jq -c .)

    local tmp=$(mktemp)
    cat "$CONFIG_FILE" | jq --arg n "$name" --argjson v "$escaped_config" '. + {($n): $v}' > "$tmp"
    mv "$tmp" "$CONFIG_FILE"
}

delete_config() {
    local name="$1"
    init_config_file

    local tmp=$(mktemp)
    cat "$CONFIG_FILE" | jq "del(.[\"$name\"])" > "$tmp"
    mv "$tmp" "$CONFIG_FILE"
}

config_exists() {
    local name="$1"
    init_config_file
    cat "$CONFIG_FILE" | jq -e ".[\"$name\"]" >/dev/null 2>&1
}

list_config_names() {
    local content=$(load_configs)
    echo "$content" | jq -r 'keys[]' 2>/dev/null | sort
}

# ============================================
# Settings Management
# ============================================

create_settings_json() {
    local config_json="$1"

    local base_url=$(echo "$config_json" | jq -r '.base_url')
    local auth_token=$(echo "$config_json" | jq -r '.auth_token')
    local opus_model=$(echo "$config_json" | jq -r '.opus_model')
    local sonnet_model=$(echo "$config_json" | jq -r '.sonnet_model')
    local haiku_model=$(echo "$config_json" | jq -r '.haiku_model')

    cat <<EOF
{
  "env": {
    "ANTHROPIC_BASE_URL": "$base_url",
    "ANTHROPIC_AUTH_TOKEN": "$auth_token",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$opus_model",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$sonnet_model",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "$haiku_model"
  },
  "alwaysThinkingEnabled": false
}
EOF
}

switch_config() {
    local name="$1"

    if ! config_exists "$name"; then
        echo -e "  ${RED}✗ Configuration '$name' not found${NC}"
        return 1
    fi

    local config=$(get_config "$name")
    if [[ -z "$config" ]]; then
        echo -e "  ${RED}✗ Invalid configuration for '$name'${NC}"
        return 1
    fi

    mkdir -p "$(dirname "$SETTINGS_FILE")"

    if [[ -f "$SETTINGS_FILE" ]]; then
        local backup="${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$SETTINGS_FILE" "$backup"
    fi

    create_settings_json "$config" > "$SETTINGS_FILE"
    echo -e "  ${GREEN}✓ Switched to: $name${NC}"
}

get_current_config() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        echo ""
        return
    fi

    for name in $(list_config_names); do
        local cfg=$(get_config "$name")
        if [[ -z "$cfg" ]]; then continue; fi

        local current_base=$(cat "$SETTINGS_FILE" | jq -r '.env.ANTHROPIC_BASE_URL' 2>/dev/null)
        local cfg_base=$(echo "$cfg" | jq -r '.base_url')

        if [[ "$current_base" == "$cfg_base" ]]; then
            echo "$name"
            return
        fi
    done

    echo "custom"
}

# ============================================
# TUI Functions
# ============================================

clear_screen() {
    printf '\033[2J\033[H'
}

draw_header() {
    echo ""
    echo -e "  ${BOLD}${PURPLE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}███╗   ███╗ █████╗ ██╗     ██╗     ███████╗████████╗${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}████╗ ████║██╔══██╗██║     ██║     ██╔════╝╚══██╔══╝${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}██╔████╔██║███████║██║     ██║     █████╗     ██║   ${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}██║╚██╔╝██║██╔══██║██║     ██║     ██╔══╝     ██║   ${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}██║ ╚═╝ ██║██║  ██║███████╗███████╗███████╗   ██║   ${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}║${NC}  ${BOLD}${WHITE}╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝   ${NC}   ${PURPLE}║${NC}"
    echo -e "  ${PURPLE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${DIM}${GRAY}                    v${VERSION} — Model Configuration Manager${NC}"
    echo ""
}

draw_config_card() {
    local name="$1"
    local config="$2"

    local base_url=$(echo "$config" | jq -r '.base_url' 2>/dev/null)
    local opus=$(echo "$config" | jq -r '.opus_model' 2>/dev/null)
    local sonnet=$(echo "$config" | jq -r '.sonnet_model' 2>/dev/null)
    local haiku=$(echo "$config" | jq -r '.haiku_model' 2>/dev/null)

    echo -e "  ${CYAN}┌───────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC}  ${BOLD}${GREEN}$name${NC}"
    printf "  ${CYAN}│${NC}   ${DIM}%-52s${NC}" "$base_url"
    echo -e "${CYAN}║${NC}"
    echo -e "  ${CYAN}│${NC}   ${YELLOW}Opus:${NC}   $opus"
    echo -e "  ${CYAN}│${NC}   ${YELLOW}Sonnet:${NC} $sonnet"
    echo -e "  ${CYAN}│${NC}   ${YELLOW}Haiku:${NC}  $haiku"
    echo -e "  ${CYAN}└───────────────────────────────────────────────────────┘${NC}"
}

draw_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=${selected_idx:-0}
    local width=50

    echo -e "  ${BOLD}${CYAN}┌────────────────────────────────────────────────┐${NC}"
    echo -e "  ${CYAN}│${NC}  ${BOLD}${WHITE}$title${NC}"
    printf "  ${CYAN}│${NC}  %*s" $((width - 3)) ""
    echo -e "${CYAN}║${NC}"

    for ((i=0; i<${#options[@]}; i++)); do
        local prefix="  ${CYAN}│${NC}   "
        if [[ $i -eq $selected ]]; then
            echo -e "${prefix}${GREEN}▶${NC} ${BOLD}${WHITE}${options[$i]}${NC}"
        else
            echo -e "${prefix}  ${GRAY}${options[$i]}${NC}"
        fi
    done

    echo -e "  ${CYAN}│${NC}"
    echo -e "  ${CYAN}│${NC}  ${DIM}${GRAY}↑↓ to navigate • Enter to select • q to quit${NC}"
    echo -e "  ${CYAN}└────────────────────────────────────────────────┘${NC}"
}

handle_input() {
    local input
    read -rsn1 input 2>/dev/null

    case "$input" in
        $'\x1b')
            read -rsn2 input 2>/dev/null
            case "$input" in
                '[A') echo "UP" ;;
                '[B') echo "DOWN" ;;
                *) echo "UNKNOWN" ;;
            esac
            ;;
        '')
            echo "ENTER" ;;
        'q'|'Q')
            echo "QUIT" ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# ============================================
# TUI Menus
# ============================================

main_menu() {
    selected_idx=0
    local options=("Switch Config" "Add Config" "Edit Config" "Delete Config" "View Current" "List All" "About" "Exit")

    while true; do
        clear_screen
        draw_header
        draw_menu "Main Menu" "${options[@]}"

        local action=$(handle_input)

        case "$action" in
            "UP")
                ((selected_idx--))
                [[ $selected_idx -lt 0 ]] && selected_idx=$((${#options[@]} - 1))
                ;;
            "DOWN")
                ((selected_idx++))
                [[ $selected_idx -ge ${#options[@]} ]] && selected_idx=0
                ;;
            "ENTER")
                case "$selected_idx" in
                    0) config_menu ;;
                    1) add_config_menu ;;
                    2) edit_config_menu ;;
                    3) delete_config_menu ;;
                    4) current_menu ;;
                    5) list_menu ;;
                    6) about_menu ;;
                    7) clear_screen; exit 0 ;;
                esac
                ;;
            "QUIT")
                clear_screen
                exit 0
                ;;
        esac
    done
}

config_menu() {
    selected_idx=0
    local names=($(list_config_names))
    local total=${#names[@]}

    while true; do
        clear_screen
        draw_header
        echo -e "  ${BOLD}${CYAN}Select Configuration:${NC}"
        echo ""

        for ((i=0; i<total; i++)); do
            local name="${names[$i]}"
            if [[ $i -eq $selected_idx ]]; then
                draw_config_card "$name" "$(get_config "$name")"
                echo ""
            fi
        done

        local action=$(handle_input)

        case "$action" in
            "UP")
                ((selected_idx--))
                [[ $selected_idx -lt 0 ]] && selected_idx=$((total - 1))
                ;;
            "DOWN")
                ((selected_idx++))
                [[ $selected_idx -ge $total ]] && selected_idx=0
                ;;
            "ENTER")
                switch_config "${names[$selected_idx]}"
                sleep 1.5
                return
                ;;
            "QUIT"|"LEFT")
                return
                ;;
        esac
    done
}

add_config_menu() {
    clear_screen
    draw_header
    echo -e "  ${BOLD}${CYAN}Add New Configuration${NC}"
    echo ""
    echo -e "  ${GRAY}Enter details below (press Enter to use default values):${NC}"
    echo ""

    read -p "  Name: " name
    [[ -z "$name" ]] && { echo "  ${RED}✗ Name is required${NC}"; sleep 1; return; }

    if config_exists "$name"; then
        echo "  ${RED}✗ Configuration '$name' already exists${NC}"
        sleep 1.5
        return
    fi

    read -p "  Base URL: " base_url
    [[ -z "$base_url" ]] && base_url="https://api.example.com/anthropic"

    read -p "  Auth Token: " auth_token
    [[ -z "$auth_token" ]] && auth_token="YOUR_TOKEN_HERE"

    read -p "  Opus Model: " opus_model
    [[ -z "$opus_model" ]] && opus_model="claude-3-opus-20240229"

    read -p "  Sonnet Model: " sonnet_model
    [[ -z "$sonnet_model" ]] && sonnet_model="claude-3-5-sonnet-20241022"

    read -p "  Haiku Model: " haiku_model
    [[ -z "$haiku_model" ]] && haiku_model="claude-3-haiku-20240307"

    local new_config=$(cat <<EOF
{
  "base_url": "$base_url",
  "auth_token": "$auth_token",
  "opus_model": "$opus_model",
  "sonnet_model": "$sonnet_model",
  "haiku_model": "$haiku_model"
}
EOF
)

    save_config "$name" "$new_config"
    echo ""
    echo -e "  ${GREEN}✓ Added configuration: $name${NC}"
    sleep 1.5
}

edit_config_menu() {
    selected_idx=0
    local names=($(list_config_names))
    local total=${#names[@]}

    [[ $total -eq 0 ]] && { echo "  ${YELLOW}No configurations to edit${NC}"; sleep 1.5; return; }

    while true; do
        clear_screen
        draw_header
        echo -e "  ${BOLD}${CYAN}Edit Configuration (select one):${NC}"
        echo ""

        for ((i=0; i<total; i++)); do
            local name="${names[$i]}"
            if [[ $i -eq $selected_idx ]]; then
                draw_config_card "$name" "$(get_config "$name")"
                echo ""
            fi
        done

        local action=$(handle_input)

        case "$action" in
            "UP")
                ((selected_idx--))
                [[ $selected_idx -lt 0 ]] && selected_idx=$((total - 1))
                ;;
            "DOWN")
                ((selected_idx++))
                [[ $selected_idx -ge $total ]] && selected_idx=0
                ;;
            "ENTER")
                edit_config_details "${names[$selected_idx]}"
                return
                ;;
            "QUIT"|"LEFT")
                return
                ;;
        esac
    done
}

edit_config_details() {
    local name="$1"
    local config=$(get_config "$name")

    clear_screen
    draw_header
    echo -e "  ${BOLD}${CYAN}Edit: $name${NC}"
    echo ""

    local base_url=$(echo "$config" | jq -r '.base_url')
    local auth_token=$(echo "$config" | jq -r '.auth_token')
    local opus_model=$(echo "$config" | jq -r '.opus_model')
    local sonnet_model=$(echo "$config" | jq -r '.sonnet_model')
    local haiku_model=$(echo "$config" | jq -r '.haiku_model')

    echo -e "  ${GRAY}Press Enter to keep current value${NC}"
    echo ""

    read -p "  Base URL [$base_url]: " new_url
    [[ -z "$new_url" ]] && new_url="$base_url"

    read -p "  Auth Token [******]: " new_token
    [[ -z "$new_token" ]] && new_token="$auth_token"

    read -p "  Opus Model [$opus_model]: " new_opus
    [[ -z "$new_opus" ]] && new_opus="$opus_model"

    read -p "  Sonnet Model [$sonnet_model]: " new_sonnet
    [[ -z "$new_sonnet" ]] && new_sonnet="$sonnet_model"

    read -p "  Haiku Model [$haiku_model]: " new_haiku
    [[ -z "$new_haiku" ]] && new_haiku="$haiku_model"

    local updated_config=$(cat <<EOF
{
  "base_url": "$new_url",
  "auth_token": "$new_token",
  "opus_model": "$new_opus",
  "sonnet_model": "$new_sonnet",
  "haiku_model": "$new_haiku"
}
EOF
)

    save_config "$name" "$updated_config"
    echo ""
    echo -e "  ${GREEN}✓ Updated configuration: $name${NC}"
    sleep 1.5
}

delete_config_menu() {
    selected_idx=0
    local names=($(list_config_names))
    local total=${#names[@]}

    [[ $total -eq 0 ]] && { echo "  ${YELLOW}No configurations to delete${NC}"; sleep 1.5; return; }

    while true; do
        clear_screen
        draw_header
        echo -e "  ${BOLD}${RED}Delete Configuration${NC}"
        echo ""
        echo -e "  ${YELLOW}⚠ Warning: This cannot be undone${NC}"
        echo ""

        for ((i=0; i<total; i++)); do
            local name="${names[$i]}"
            if [[ $i -eq $selected_idx ]]; then
                draw_config_card "$name" "$(get_config "$name")"
                echo ""
            fi
        done

        local action=$(handle_input)

        case "$action" in
            "UP")
                ((selected_idx--))
                [[ $selected_idx -lt 0 ]] && selected_idx=$((total - 1))
                ;;
            "DOWN")
                ((selected_idx++))
                [[ $selected_idx -ge $total ]] && selected_idx=0
                ;;
            "ENTER")
                local to_delete="${names[$selected_idx]}"
                echo ""
                read -p "  Delete '$to_delete'? [y/N] " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    delete_config "$to_delete"
                    echo -e "  ${GREEN}✓ Deleted: $to_delete${NC}"
                else
                    echo "  Cancelled"
                fi
                sleep 1.5
                return
                ;;
            "QUIT"|"LEFT")
                return
                ;;
        esac
    done
}

current_menu() {
    clear_screen
    draw_header
    echo -e "  ${BOLD}${CYAN}Current Configuration:${NC}"
    echo ""

    local current=$(get_current_config)
    if [[ -n "$current" ]]; then
        draw_config_card "$current (ACTIVE)" "$(get_config "$current")"
    else
        echo -e "  ${YELLOW}No configuration found${NC}"
    fi

    echo ""
    echo -e "  ${DIM}${GRAY}Press any key to go back...${NC}"

    handle_input
    return
}

list_menu() {
    selected_idx=0
    local names=($(list_config_names))
    local total=${#names[@]}

    while true; do
        clear_screen
        draw_header
        echo -e "  ${BOLD}${CYAN}All Configurations:${NC}"
        echo ""

        for ((i=0; i<total; i++)); do
            local name="${names[$i]}"
            local base_url=$(get_config "$name" | jq -r '.base_url')
            if [[ $i -eq $selected_idx ]]; then
                echo -e "  ${GREEN}▶${NC} ${BOLD}$name${NC} ${DIM}($base_url)${NC}"
            else
                echo -e "    ${GRAY}$name${NC}"
            fi
        done

        echo ""
        echo -e "  ${DIM}${GRAY}↑↓ to navigate • Enter to select • q/esc to go back${NC}"

        local action=$(handle_input)

        case "$action" in
            "UP")
                ((selected_idx--))
                [[ $selected_idx -lt 0 ]] && selected_idx=$((total - 1))
                ;;
            "DOWN")
                ((selected_idx++))
                [[ $selected_idx -ge $total ]] && selected_idx=0
                ;;
            "ENTER")
                config_detail_menu "${names[$selected_idx]}"
                ;;
            "QUIT"|"LEFT")
                return
                ;;
        esac
    done
}

config_detail_menu() {
    local name="$1"
    local config=$(get_config "$name")

    while true; do
        clear_screen
        draw_header
        echo -e "  ${BOLD}${CYAN}Configuration: $name${NC}"
        echo ""
        draw_config_card "$name" "$config"
        echo ""
        echo -e "  ${GREEN}[ Enter ]${NC} Switch to this config"
        echo -e "  ${GRAY}[ q ]${NC} Go back"
        echo ""

        local action=$(handle_input)

        case "$action" in
            "ENTER")
                switch_config "$name"
                sleep 1.5
                return
                ;;
            "QUIT"|"LEFT")
                return
                ;;
        esac
    done
}

about_menu() {
    clear_screen
    draw_header
    echo -e "  ${BOLD}${CYAN}About Claude Switch${NC}"
    echo ""
    echo -e "  ${WHITE}Beautiful TUI for managing Claude Model configurations${NC}"
    echo ""
    echo -e "  ${GREEN}Version:${NC}   $VERSION"
    echo -e "  ${GREEN}Config file:${NC} ~/.claudeswitchrc"
    echo -e "  ${GREEN}License:${NC}   MIT"
    echo ""
    echo -e "  ${YELLOW}Quick Install:${NC}"
    echo -e "  ${GRAY}curl -fsSL $INSTALL_URL | bash${NC}"
    echo ""
    echo -e "  ${DIM}${GRAY}Press any key to go back...${NC}"

    handle_input
    return
}

# ============================================
# Installation
# ============================================

install_binary() {
    echo ""
    echo -e "  ${BOLD}${CYAN}Installing Claude Switch...${NC}"
    echo ""

    local sudo_cmd=""
    if [[ ! -w "/usr/local/bin" ]]; then
        if command -v sudo &>/dev/null; then
            sudo_cmd="sudo"
            echo -e "  ${YELLOW}Using sudo...${NC}"
        else
            echo -e "  ${RED}Error: Cannot write to /usr/local/bin${NC}"
            exit 1
        fi
    fi

    local script_content=$(cat "${BASH_SOURCE[0]}")

    echo -e "  ${DIM}Writing binary...${NC}"
    $sudo_cmd mkdir -p "$(dirname "$BINARY_PATH")"
    echo "#!/bin/bash
# Claude Switch v${VERSION} - Installed $(date +%Y-%m-%d)
$script_content" | $sudo_cmd tee "$BINARY_PATH" > /dev/null
    $sudo_cmd chmod +x "$BINARY_PATH"

    echo ""
    echo -e "  ${GREEN}✓ Installed to $BINARY_PATH${NC}"
    echo ""
    echo -e "  ${BOLD}Usage:${NC}"
    echo -e "    ${CYAN}claude-switch${NC}       Launch TUI"
    echo -e "    ${CYAN}claude-switch list${NC}  List configs"
    echo -e "    ${CYAN}claude-switch add${NC}   Add config"
    echo ""
}

# ============================================
# CLI Commands
# ============================================

show_help() {
    echo -e "${BLUE}Claude Switch v${VERSION}${NC}"
    echo ""
    echo "Commands:"
    echo "  tui               Launch interactive TUI (default)"
    echo "  list, ls          List all configurations"
    echo "  current, c        Show current configuration"
    echo "  switch <name>     Switch to a configuration"
    echo "  add               Add a new configuration"
    echo "  edit <name>       Edit a configuration"
    echo "  delete <name>     Delete a configuration"
    echo "  import <file>     Import from JSON file"
    echo "  export [file]     Export all configs to file"
    echo "  install           Install binary to /usr/local/bin"
    echo "  update            Update to latest version"
    echo "  uninstall         Remove the binary"
    echo ""
}

cli_add_config() {
    local name="$1"
    local base_url="$2"
    local auth_token="$3"
    local opus_model="${4:-claude-3-opus-20240229}"
    local sonnet_model="${5:-claude-3-5-sonnet-20241022}"
    local haiku_model="${6:-claude-3-haiku-20240307}"

    [[ -z "$name" ]] && { echo "Usage: claude-switch add <name> <base_url> <auth_token> [opus] [sonnet] [haiku]"; exit 1; }
    [[ -z "$base_url" ]] && { echo "Error: base_url required"; exit 1; }
    [[ -z "$auth_token" ]] && { echo "Error: auth_token required"; exit 1; }

    if config_exists "$name"; then
        echo -e "  ${RED}✗ Configuration '$name' already exists${NC}"
        exit 1
    fi

    local config=$(cat <<EOF
{
  "base_url": "$base_url",
  "auth_token": "$auth_token",
  "opus_model": "$opus_model",
  "sonnet_model": "$sonnet_model",
  "haiku_model": "$haiku_model"
}
EOF
)

    save_config "$name" "$config"
    echo -e "  ${GREEN}✓ Added: $name${NC}"
}

cli_edit_config() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: claude-switch edit <name>"; exit 1; }
    if ! config_exists "$name"; then
        echo -e "  ${RED}✗ Configuration '$name' not found${NC}"
        exit 1
    fi
    edit_config_details "$name"
}

cli_delete_config() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: claude-switch delete <name>"; exit 1; }
    if ! config_exists "$name"; then
        echo -e "  ${RED}✗ Configuration '$name' not found${NC}"
        exit 1
    fi
    delete_config "$name"
    echo -e "  ${GREEN}✓ Deleted: $name${NC}"
}

cli_import() {
    local file="$1"
    [[ -z "$file" ]] && { echo "Usage: claude-switch import <file.json>"; exit 1; }
    [[ ! -f "$file" ]] && { echo "Error: File not found"; exit 1; }

    local tmp=$(mktemp)
    cat "$CONFIG_FILE" > "$tmp"
    cat "$file" | jq -s '.[0] * .[1]' "$tmp" - > "$CONFIG_FILE"
    rm -f "$tmp"
    echo -e "  ${GREEN}✓ Imported from: $file${NC}"
}

cli_export() {
    local file="${1:-/dev/stdout}"
    cat "$CONFIG_FILE" > "$file"
    [[ -n "$1" ]] && echo -e "  ${GREEN}✓ Exported to: $file${NC}"
}

# ============================================
# Main Entry Point
# ============================================

main() {
    # Check jq dependency
    if ! command -v jq &>/dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${NC}"
        exit 1
    fi

    # Handle CLI commands
    case "${1:-}" in
        install|--install)
            install_binary
            ;;
        list|ls)
            echo ""
            echo -e "  ${BOLD}${BLUE}Configurations:${NC}"
            echo ""
            for name in $(list_config_names); do
                echo -e "    ${GREEN}$name${NC}"
            done
            echo ""
            ;;
        current|c)
            echo ""
            echo -e "  ${BOLD}${BLUE}Current:${NC} $(get_current_config)"
            echo ""
            ;;
        switch)
            [[ -z "$2" ]] && { echo "Usage: claude-switch switch <name>"; exit 1; }
            switch_config "$2"
            ;;
        add)
            shift
            cli_add_config "$@"
            ;;
        edit)
            shift
            cli_edit_config "$@"
            ;;
        delete|rm|remove)
            shift
            cli_delete_config "$@"
            ;;
        import)
            shift
            cli_import "$@"
            ;;
        export)
            shift
            cli_export "$@"
            ;;
        tui)
            if [[ -t 0 ]] && [[ -t 1 ]]; then
                main_menu
            else
                echo "Interactive TUI requires a terminal"
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        update)
            curl -fsSL "$INSTALL_URL" | bash
            ;;
        uninstall|remove)
            rm -f "$BINARY_PATH"
            echo -e "  ${GREEN}✓ Uninstalled${NC}"
            ;;
        "")
            if [[ -t 0 ]] && [[ -t 1 ]]; then
                main_menu
            else
                show_help
            fi
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
