#!/bin/sh
# install.sh — Symlink agent-cli-playbook to all detected global platforms
#
# Usage:
#   ./install.sh              # Symlink to all detected platforms
#   ./install.sh --dry-run    # Preview without making changes
#   ./install.sh --uninstall  # Remove all symlinks pointing to this repo
#
# POSIX-compatible (works in bash, dash, zsh, ash).

set -eu

SKILL_NAME="agent-cli-playbook"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors (disabled when stdout is not a terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m'
    RED='\033[0;31m' BOLD='\033[1m' NC='\033[0m'
else
    GREEN='' YELLOW='' BLUE='' RED='' BOLD='' NC=''
fi

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

DRY_RUN=false
UNINSTALL=false

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)   DRY_RUN=true ;;
        --uninstall) UNINSTALL=true ;;
        -h|--help)
            printf "Usage: %s [--dry-run] [--uninstall]\n\n" "$0"
            printf "Detects installed AI coding tools and symlinks this skill to each.\n\n"
            printf "Options:\n"
            printf "  --dry-run     Preview without making changes\n"
            printf "  --uninstall   Remove all symlinks pointing to this repo\n"
            printf "  -h, --help    Show this help message\n"
            exit 0
            ;;
        *) error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Platform entries: <detection_dir>|<install_path>|<display_name>
all_platform_entries() {
    cat <<PLATFORMS
$HOME/.claude|$HOME/.claude/skills/$SKILL_NAME|Claude Code
$HOME/.gemini|$HOME/.gemini/skills/$SKILL_NAME|Gemini CLI
$HOME/.config/goose|$HOME/.config/goose/skills/$SKILL_NAME|Goose
$HOME/.config/opencode|$HOME/.config/opencode/skills/$SKILL_NAME|OpenCode
$HOME/.copilot|$HOME/.copilot/skills/$SKILL_NAME|GitHub Copilot
PLATFORMS
}

create_symlink() {
    target="$1"; link_path="$2"
    [ "$target" = "$link_path" ] && return 0
    mkdir -p "$(dirname "$link_path")"
    [ -e "$link_path" ] || [ -L "$link_path" ] && rm -rf "$link_path"
    if ! ln -s "$target" "$link_path" 2>/dev/null; then
        warn "Symlink failed for $link_path — falling back to copy"
        cp -R "$target" "$link_path"
    fi
}

do_uninstall() {
    printf "\n${BOLD}Uninstalling %s symlinks${NC}\n\n" "$SKILL_NAME"

    canonical="$HOME/.agents/skills/$SKILL_NAME"
    if [ -L "$canonical" ]; then
        link_target="$(readlink "$canonical" 2>/dev/null || true)"
        if [ "$link_target" = "$REPO_DIR" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "[dry-run] Would remove: $canonical"
            else
                rm "$canonical"; success "Removed: $canonical"
            fi
        fi
    fi

    all_platform_entries | while IFS='|' read -r _ install_path display_name; do
        dest="$install_path"
        if [ -L "$dest" ]; then
            link_target="$(readlink "$dest" 2>/dev/null || true)"
            if [ "$link_target" = "$REPO_DIR" ]; then
                if [ "$DRY_RUN" = true ]; then
                    info "[dry-run] Would remove: $dest"
                else
                    rm "$dest"; success "Removed: $dest ($display_name)"
                fi
            fi
        fi
    done

    if [ "$DRY_RUN" = true ]; then
        printf "\n${YELLOW}Dry run — no changes made.${NC}\n"
    else
        printf "\nDone.\n"
    fi
}

do_install() {
    printf "\n${BOLD}Agent CLI Playbook — Installer${NC}\n\n"
    info "Source: $REPO_DIR"

    # Always install to canonical location (~/.agents/skills/)
    canonical="$HOME/.agents/skills/$SKILL_NAME"
    if [ "$DRY_RUN" = true ]; then
        info "[dry-run] Would symlink: $canonical"
    else
        create_symlink "$REPO_DIR" "$canonical"
        success "Canonical: $canonical"
    fi

    # Install to each detected platform
    all_platform_entries | while IFS='|' read -r detect_dir install_path display_name; do
        if [ -d "$detect_dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                info "[dry-run] Would symlink: $install_path ($display_name)"
            else
                create_symlink "$REPO_DIR" "$install_path"
                success "$display_name → $install_path"
            fi
        fi
    done

    printf "\n${BOLD}Done!${NC}\n\n"
    if [ "$DRY_RUN" = true ]; then
        printf "${YELLOW}Dry run — no changes made.${NC}\n\n"
    else
        printf "  Run ${BOLD}git pull${NC} in %s to update all tools.\n\n" "$REPO_DIR"
    fi
}

if [ "$UNINSTALL" = true ]; then
    do_uninstall
else
    do_install
fi
