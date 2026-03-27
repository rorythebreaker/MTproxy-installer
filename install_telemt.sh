#!/usr/bin/env bash
# ==============================================================================
# Telemt Installer — Interactive TUI
# Supports Debian-based Linux distributions
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Color Scheme
# ------------------------------------------------------------------------------
C_RESET="\033[0m"
C_BOLD="\033[1m"

# Primary palette
C_BG_HEADER="\033[48;2;15;23;42m"       # Deep navy background
C_ACCENT="\033[38;2;56;189;248m"         # Cyan accent
C_ACCENT2="\033[38;2;99;235;187m"        # Mint green
C_WARN="\033[38;2;251;191;36m"           # Amber warning
C_ERROR="\033[38;2;239;68;68m"           # Red error
C_SUCCESS="\033[38;2;34;197;94m"         # Green success
C_DIM="\033[38;2;100;116;139m"           # Slate dim
C_WHITE="\033[38;2;241;245;249m"         # Near-white
C_LABEL="\033[38;2;148;163;184m"         # Soft label
C_INPUT="\033[38;2;224;242;254m"         # Input text
C_BORDER="\033[38;2;30;58;95m"           # Border color
C_HIGHLIGHT="\033[48;2;30;58;95m"        # Row highlight bg

# Box drawing
BOX_TL="╔"; BOX_TR="╗"; BOX_BL="╚"; BOX_BR="╝"
BOX_H="═"; BOX_V="║"
BOX_ML="╠"; BOX_MR="╣"
BOX_LT="╟"; BOX_RT="╢"
DIV_H="─"

# ------------------------------------------------------------------------------
# Terminal helpers
# ------------------------------------------------------------------------------
TERM_W=0
get_term_width() {
    TERM_W=$(tput cols 2>/dev/null || echo 80)
    [[ $TERM_W -lt 60 ]] && TERM_W=60
    [[ $TERM_W -gt 120 ]] && TERM_W=120
}

draw_hline() {
    local char="${1:-$BOX_H}" left="${2:-$BOX_ML}" right="${3:-$BOX_MR}"
    local inner=$(( TERM_W - 2 ))
    local line=""
    for (( i=0; i<inner; i++ )); do line+="$char"; done
    echo -e "${C_ACCENT}${left}${line}${right}${C_RESET}"
}

draw_border_top() {
    local inner=$(( TERM_W - 2 ))
    local line=""
    for (( i=0; i<inner; i++ )); do line+="$BOX_H"; done
    echo -e "${C_ACCENT}${BOX_TL}${line}${BOX_TR}${C_RESET}"
}

draw_border_bot() {
    local inner=$(( TERM_W - 2 ))
    local line=""
    for (( i=0; i<inner; i++ )); do line+="$BOX_H"; done
    echo -e "${C_ACCENT}${BOX_BL}${line}${BOX_BR}${C_RESET}"
}

# Print a row padded to terminal width
row() {
    local text="$1"
    # Strip ANSI for length calculation
    local plain
    plain=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local visible_len=${#plain}
    local inner=$(( TERM_W - 2 ))
    local pad=$(( inner - visible_len ))
    [[ $pad -lt 0 ]] && pad=0
    local spaces
    printf -v spaces '%*s' "$pad" ''
    echo -e "${C_ACCENT}${BOX_V}${C_RESET}${text}${spaces}${C_ACCENT}${BOX_V}${C_RESET}"
}

row_empty() {
    row ""
}

clear_screen() {
    clear
    get_term_width
}

# ------------------------------------------------------------------------------
# Header / Footer
# ------------------------------------------------------------------------------
draw_header() {
    clear_screen
    draw_border_top
    row ""
    row "  ${C_BOLD}${C_ACCENT}  ████████╗███████╗██╗     ███████╗███╗   ███╗████████╗${C_RESET}"
    row "  ${C_BOLD}${C_ACCENT}     ██╔══╝██╔════╝██║     ██╔════╝████╗ ████║╚══██╔══╝${C_RESET}"
    row "  ${C_BOLD}${C_ACCENT}     ██║   █████╗  ██║     █████╗  ██╔████╔██║   ██║   ${C_RESET}"
    row "  ${C_BOLD}${C_ACCENT}     ██║   ██╔══╝  ██║     ██╔══╝  ██║╚██╔╝██║   ██║   ${C_RESET}"
    row "  ${C_BOLD}${C_ACCENT}     ██║   ███████╗███████╗███████╗██║ ╚═╝ ██║   ██║   ${C_RESET}"
    row "  ${C_BOLD}${C_ACCENT}     ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝   ╚═╝   ${C_RESET}"
    row ""
    row "  ${C_LABEL}Telegram MTProxy Server Installer${C_RESET}  ${C_DIM}|${C_RESET}  ${C_ACCENT2}Debian-based Linux${C_RESET}"
    row ""
    draw_hline "$BOX_H"
}

draw_footer() {
    draw_hline "$DIV_H" "$BOX_LT" "$BOX_RT"
    row "  ${C_DIM}[ENTER] Confirm   [Q/Ctrl+C] Quit${C_RESET}"
    draw_border_bot
}

# ------------------------------------------------------------------------------
# Utility: prompt with validation
# ------------------------------------------------------------------------------
prompt_value() {
    # $1 = label, $2 = default, $3 = var_name_ref
    local label="$1" default="$2"
    local __result_var="$3"
    local value=""
    while true; do
        echo -ne "  ${C_ACCENT}▸${C_RESET} ${C_WHITE}${label}${C_RESET}"
        [[ -n "$default" ]] && echo -ne " ${C_DIM}[${default}]${C_RESET}"
        echo -ne " : ${C_INPUT}"
        read -r value
        echo -ne "${C_RESET}"
        [[ -z "$value" && -n "$default" ]] && value="$default"
        [[ -n "$value" ]] && break
        echo -e "  ${C_ERROR}✗ Value cannot be empty.${C_RESET}"
    done
    printf -v "$__result_var" '%s' "$value"
}

prompt_secret() {
    local label="$1"
    local __result_var="$2"
    local value=""
    while true; do
        echo -e "  ${C_ACCENT}▸${C_RESET} ${C_WHITE}${label}${C_RESET}"
        echo -ne "    ${C_DIM}(leave blank to auto-generate)${C_RESET} : ${C_INPUT}"
        read -r value
        echo -ne "${C_RESET}"
        if [[ -z "$value" ]]; then
            value=$(openssl rand -hex 16 2>/dev/null || xxd -l 16 -p /dev/urandom 2>/dev/null || python3 -c 'import os; print(os.urandom(16).hex())')
            echo -e "  ${C_SUCCESS}✔ Generated secret:${C_RESET} ${C_ACCENT2}${value}${C_RESET}"
            break
        fi
        if [[ ${#value} -eq 32 && "$value" =~ ^[0-9a-fA-F]+$ ]]; then
            break
        fi
        echo -e "  ${C_ERROR}✗ Secret must be exactly 32 hex characters.${C_RESET}"
    done
    printf -v "$__result_var" '%s' "$value"
}

confirm() {
    local msg="$1"
    echo -ne "  ${C_WARN}?${C_RESET} ${C_WHITE}${msg}${C_RESET} ${C_DIM}[Y/n]${C_RESET} : "
    read -r ans
    [[ "$ans" =~ ^[Nn]$ ]] && return 1
    return 0
}

info()    { echo -e "  ${C_ACCENT}•${C_RESET} $*"; }
success() { echo -e "  ${C_SUCCESS}✔${C_RESET} $*"; }
warn()    { echo -e "  ${C_WARN}⚠${C_RESET} $*"; }
error()   { echo -e "  ${C_ERROR}✗${C_RESET} $*"; }
step()    { echo -e "\n  ${C_BOLD}${C_ACCENT2}[$1]${C_RESET} ${C_WHITE}$2${C_RESET}"; }
divider() { echo -e "  ${C_DIM}$(printf '%*s' $(( TERM_W - 4 )) '' | tr ' ' '─')${C_RESET}"; }

die() {
    error "$*"
    echo ""
    draw_border_bot
    exit 1
}

# ------------------------------------------------------------------------------
# Prerequisite checks
# ------------------------------------------------------------------------------
check_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root (or via sudo)."
    fi
}

check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        die "This installer requires a Debian-based Linux distribution."
    fi
}

check_deps() {
    local missing=()
    for cmd in wget tar openssl useradd systemctl curl; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing tools: ${missing[*]}"
        info "Attempting to install missing packages..."
        apt-get update -qq && apt-get install -y -qq "${missing[@]}" \
            || die "Failed to install dependencies: ${missing[*]}"
        success "Dependencies installed."
    fi
}

check_jq() {
    if ! command -v jq &>/dev/null; then
        info "jq not found — installing..."
        apt-get install -y -qq jq || warn "jq install failed; link display may be limited."
    fi
}

# ------------------------------------------------------------------------------
# Step: detect architecture & download telemt
# ------------------------------------------------------------------------------
step_download() {
    step "1/6" "Downloading Telemt binary"
    divider

    local arch libc url
    arch=$(uname -m)
    if ldd --version 2>&1 | grep -qi musl; then
        libc="musl"
    else
        libc="gnu"
    fi

    url="https://github.com/telemt/telemt/releases/latest/download/telemt-${arch}-linux-${libc}.tar.gz"
    info "Architecture : ${C_ACCENT2}${arch}${C_RESET}"
    info "libc variant : ${C_ACCENT2}${libc}${C_RESET}"
    info "URL          : ${C_DIM}${url}${C_RESET}"
    echo ""

    if [[ -f /bin/telemt ]]; then
        warn "Binary already exists at /bin/telemt."
        if ! confirm "Overwrite existing binary?"; then
            info "Skipping download — using existing binary."
            return
        fi
    fi

    info "Downloading..."
    wget -qO- "$url" | tar -xz -C /tmp/ \
        || die "Download failed. Check your internet connection and try again."

    mv /tmp/telemt /bin/telemt
    chmod +x /bin/telemt
    success "Binary installed at /bin/telemt"
}

# ------------------------------------------------------------------------------
# Step: port selection & secret generation
# ------------------------------------------------------------------------------
step_config_params() {
    step "2/6" "Configuration Parameters"
    divider

    # Port
    local port_input=""
    while true; do
        echo -ne "  ${C_ACCENT}▸${C_RESET} ${C_WHITE}Listening port${C_RESET} ${C_DIM}[443]${C_RESET} : ${C_INPUT}"
        read -r port_input
        echo -ne "${C_RESET}"
        [[ -z "$port_input" ]] && port_input="443"
        if [[ "$port_input" =~ ^[0-9]+$ ]] && (( port_input >= 1 && port_input <= 65535 )); then
            break
        fi
        error "Enter a valid port number (1–65535)."
    done
    CFG_PORT="$port_input"

    # Check port availability
    if command -v netstat &>/dev/null; then
        if netstat -lnp 2>/dev/null | grep -q ":${CFG_PORT} "; then
            warn "Port ${CFG_PORT} appears to be in use!"
            warn "Current listeners on that port:"
            netstat -lnp 2>/dev/null | grep ":${CFG_PORT} " | sed 's/^/      /'
            confirm "Continue anyway?" || die "Aborted by user."
        else
            success "Port ${CFG_PORT} is available."
        fi
    else
        warn "netstat not found — skipping port availability check."
    fi

    echo ""

    # TLS domain
    prompt_value "TLS masking domain (e.g. example.com)" "petrovich.ru" CFG_DOMAIN
    warn "Changing the domain later will invalidate all existing connection links!"
    echo ""

    # Username
    prompt_value "Username for the proxy user" "admin" CFG_USERNAME
    echo ""

    # Secret
    prompt_secret "Secret (32 hex chars)" CFG_SECRET
    echo ""

    # API listen
    echo -e "  ${C_LABEL}API will listen on 127.0.0.1:9091 (default). You can change this.${C_RESET}"
    prompt_value "API listen address" "127.0.0.1:9091" CFG_API_LISTEN
}

# ------------------------------------------------------------------------------
# Step: write config file
# ------------------------------------------------------------------------------
step_write_config() {
    step "3/6" "Writing Configuration File"
    divider

    local config_dir="/etc/telemt"
    local config_file="${config_dir}/telemt.toml"

    if [[ -f "$config_file" ]]; then
        warn "Config file already exists: ${config_file}"
        if ! confirm "Overwrite existing config?"; then
            info "Keeping existing config."
            return
        fi
        cp "$config_file" "${config_file}.bak.$(date +%Y%m%d%H%M%S)"
        info "Backup saved."
    fi

    mkdir -p "$config_dir"

    cat > "$config_file" <<TOML
# === General Settings ===
[general]
# ad_tag = "00000000000000000000000000000000"
use_middle_proxy = false

[general.modes]
classic = false
secure  = false
tls     = true

[server]
port = ${CFG_PORT}

[server.api]
enabled = true
listen  = "${CFG_API_LISTEN}"
# whitelist  = ["127.0.0.1/32"]
# read_only  = true

# === Anti-Censorship & Masking ===
[censorship]
tls_domain = "${CFG_DOMAIN}"

[access.users]
# format: "username" = "32_hex_chars_secret"
${CFG_USERNAME} = "${CFG_SECRET}"
TOML

    success "Config written to ${config_file}"
}

# ------------------------------------------------------------------------------
# Step: create system user
# ------------------------------------------------------------------------------
step_create_user() {
    step "4/6" "Creating System User"
    divider

    if id telemt &>/dev/null; then
        info "System user 'telemt' already exists."
    else
        useradd -d /opt/telemt -m -r -U telemt \
            || die "Failed to create user 'telemt'."
        success "User 'telemt' created."
    fi

    chown -R telemt:telemt /etc/telemt
    success "Ownership of /etc/telemt set to telemt:telemt"
}

# ------------------------------------------------------------------------------
# Step: create systemd service
# ------------------------------------------------------------------------------
step_create_service() {
    step "5/6" "Creating Systemd Service"
    divider

    local service_file="/etc/systemd/system/telemt.service"

    if [[ -f "$service_file" ]]; then
        warn "Service file already exists."
        if ! confirm "Overwrite existing service file?"; then
            info "Keeping existing service file."
        else
            cat > "$service_file" <<'UNIT'
[Unit]
Description=Telemt
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=telemt
Group=telemt
WorkingDirectory=/opt/telemt
ExecStart=/bin/telemt /etc/telemt/telemt.toml
Restart=on-failure
LimitNOFILE=65536
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
UNIT
            success "Service file written."
        fi
    else
        cat > "$service_file" <<'UNIT'
[Unit]
Description=Telemt
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=telemt
Group=telemt
WorkingDirectory=/opt/telemt
ExecStart=/bin/telemt /etc/telemt/telemt.toml
Restart=on-failure
LimitNOFILE=65536
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
UNIT
        success "Service file created at ${service_file}"
    fi

    systemctl daemon-reload
    success "Systemd configuration reloaded."
}

# ------------------------------------------------------------------------------
# Step: enable/start service
# ------------------------------------------------------------------------------
step_start_service() {
    step "6/6" "Starting Telemt Service"
    divider

    local do_enable=true do_start=true

    if ! confirm "Enable telemt to start automatically at boot?"; then
        do_enable=false
    fi
    if ! confirm "Start telemt service now?"; then
        do_start=false
    fi

    if $do_enable; then
        systemctl enable telemt
        success "Service enabled for autostart."
    fi

    if $do_start; then
        systemctl start telemt
        sleep 1
        if systemctl is-active --quiet telemt; then
            success "Service is running."
        else
            error "Service failed to start. Check logs:"
            echo ""
            journalctl -u telemt -n 20 --no-pager | sed 's/^/      /'
            echo ""
        fi
    fi
}

# ------------------------------------------------------------------------------
# Summary screen
# ------------------------------------------------------------------------------
show_summary() {
    echo ""
    draw_hline "$BOX_H"
    row ""
    row "  ${C_BOLD}${C_ACCENT2}  Installation Summary${C_RESET}"
    row ""
    row "  ${C_LABEL}Binary         ${C_RESET}  ${C_WHITE}/bin/telemt${C_RESET}"
    row "  ${C_LABEL}Config file    ${C_RESET}  ${C_WHITE}/etc/telemt/telemt.toml${C_RESET}"
    row "  ${C_LABEL}Service        ${C_RESET}  ${C_WHITE}telemt.service${C_RESET}"
    row "  ${C_LABEL}Port           ${C_RESET}  ${C_WHITE}${CFG_PORT}${C_RESET}"
    row "  ${C_LABEL}TLS domain     ${C_RESET}  ${C_WHITE}${CFG_DOMAIN}${C_RESET}"
    row "  ${C_LABEL}Username       ${C_RESET}  ${C_WHITE}${CFG_USERNAME}${C_RESET}"
    row "  ${C_LABEL}Secret         ${C_RESET}  ${C_ACCENT2}${CFG_SECRET}${C_RESET}"
    row ""
    draw_hline "$DIV_H" "$BOX_LT" "$BOX_RT"
    row ""
    row "  ${C_BOLD}${C_WHITE}Useful commands:${C_RESET}"
    row ""
    row "  ${C_DIM}Status   ${C_RESET}  ${C_ACCENT}systemctl status telemt${C_RESET}"
    row "  ${C_DIM}Logs     ${C_RESET}  ${C_ACCENT}journalctl -u telemt -f${C_RESET}"
    row "  ${C_DIM}Links    ${C_RESET}  ${C_ACCENT}curl -s http://${CFG_API_LISTEN}/v1/users | jq${C_RESET}"
    row "  ${C_DIM}Stop     ${C_RESET}  ${C_ACCENT}systemctl stop telemt${C_RESET}"
    row "  ${C_DIM}Restart  ${C_RESET}  ${C_ACCENT}systemctl restart telemt${C_RESET}"
    row ""
    draw_border_bot
    echo ""

    # Attempt to retrieve user links
    if systemctl is-active --quiet telemt && command -v jq &>/dev/null; then
        echo -e "  ${C_BOLD}${C_ACCENT2}Connection Links:${C_RESET}"
        local api_url="http://${CFG_API_LISTEN}/v1/users"
        local links
        links=$(curl -s "$api_url" 2>/dev/null | jq -r '.[] | .links[]?' 2>/dev/null || true)
        if [[ -n "$links" ]]; then
            echo "$links" | while IFS= read -r link; do
                echo -e "  ${C_ACCENT2}${link}${C_RESET}"
            done
        else
            warn "Could not retrieve links yet. Service may still be starting."
            info "Run:  ${C_ACCENT}curl -s http://${CFG_API_LISTEN}/v1/users | jq${C_RESET}"
        fi
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# Intro screen
# ------------------------------------------------------------------------------
intro_screen() {
    draw_header
    row ""
    row "  ${C_WHITE}This script installs and configures ${C_ACCENT}Telemt${C_RESET}${C_WHITE} — a fast MTProxy server${C_RESET}"
    row "  ${C_WHITE}for Telegram, running as a systemd service.${C_RESET}"
    row ""
    row "  ${C_LABEL}Requirements:${C_RESET}"
    row "  ${C_DIM}•${C_RESET}  ${C_WHITE}Debian-based Linux (Debian, Ubuntu, Mint, Kali, MX, ...)${C_RESET}"
    row "  ${C_DIM}•${C_RESET}  ${C_WHITE}Root privileges${C_RESET}"
    row "  ${C_DIM}•${C_RESET}  ${C_WHITE}Internet access${C_RESET}"
    row ""
    draw_footer
    echo ""
    echo -ne "  ${C_ACCENT}▸${C_RESET} ${C_WHITE}Press ENTER to begin, or Q to quit${C_RESET} : "
    read -r ans
    [[ "$ans" =~ ^[Qq]$ ]] && { echo ""; info "Aborted."; echo ""; exit 0; }
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    # Global config vars
    CFG_PORT=""
    CFG_DOMAIN=""
    CFG_USERNAME=""
    CFG_SECRET=""
    CFG_API_LISTEN=""

    intro_screen
    draw_header
    check_root
    check_debian
    check_deps
    check_jq
    echo ""

    step_download
    echo ""

    step_config_params
    echo ""

    # Confirmation before writing anything
    draw_hline "$DIV_H" "$BOX_LT" "$BOX_RT"
    row ""
    row "  ${C_BOLD}${C_WHITE}Review your settings before proceeding:${C_RESET}"
    row ""
    row "  ${C_LABEL}Port       ${C_RESET}  ${C_ACCENT2}${CFG_PORT}${C_RESET}"
    row "  ${C_LABEL}Domain     ${C_RESET}  ${C_ACCENT2}${CFG_DOMAIN}${C_RESET}"
    row "  ${C_LABEL}Username   ${C_RESET}  ${C_ACCENT2}${CFG_USERNAME}${C_RESET}"
    row "  ${C_LABEL}Secret     ${C_RESET}  ${C_ACCENT2}${CFG_SECRET}${C_RESET}"
    row "  ${C_LABEL}API listen ${C_RESET}  ${C_ACCENT2}${CFG_API_LISTEN}${C_RESET}"
    row ""
    draw_hline "$DIV_H" "$BOX_LT" "$BOX_RT"
    echo ""
    confirm "Proceed with installation?" || { info "Aborted by user."; draw_border_bot; echo ""; exit 0; }
    echo ""

    step_write_config
    echo ""

    step_create_user
    echo ""

    step_create_service
    echo ""

    step_start_service
    echo ""

    show_summary
}

main "$@"
