#!/bin/zsh

STATE_FILE="$HOME/.macbook_install_state"
LOG_FILE="$HOME/macbook_install.log"

# --- Helper Functions ---

log() {
    echo "[INFO] $1"
    echo "[$(date)] [INFO] $1" >> "$LOG_FILE"
}

success() {
    echo "[OK] $1"
    echo "[$(date)] [OK] $1" >> "$LOG_FILE"
}

warn() {
    echo "[WARN] $1"
    echo "[$(date)] [WARN] $1" >> "$LOG_FILE"
}

error() {
    echo "[ERROR] $1"
    echo "[$(date)] [ERROR] $1" >> "$LOG_FILE"
}

# Check if a specific step has been completed
is_step_completed() {
    local step_name="$1"
    if grep -q "^${step_name}$" "$STATE_FILE" 2>/dev/null; then
        return 0 # True, step completed
    else
        return 1 # False
    fi
}

# Mark a step as completed
mark_step_completed() {
    local step_name="$1"
    echo "$step_name" >> "$STATE_FILE"
}

# Wrapper to execute a step only if it hasn't been done
execute_step() {
    local step_name="$1"
    local step_func="$2"
    local step_desc="$3"

    if is_step_completed "$step_name"; then
        echo "Skipping '$step_desc' (already completed)"
    else
        log "Starting '$step_desc'..."
        if $step_func; then
            mark_step_completed "$step_name"
            success "Completed '$step_desc'"
        else
            error "Failed '$step_desc'"
            echo "To retry, run the script again."
            exit 1
        fi
    fi
}

# Retry command wrapper
run_with_retry() {
    local max_attempts=3
    local timeout=1
    local attempt=1
    local exitCode=0

    while (( attempt <= max_attempts ))
    do
        "$@"
        exitCode=$?

        if (( exitCode == 0 ))
        then
            return 0
        fi

        warn "Command failed (Attempt $attempt/$max_attempts). Retrying in $timeout seconds..."
        sleep $timeout
        (( attempt++ ))
        (( timeout++ ))
    done

    error "Command failed after $max_attempts attempts."
    return $exitCode
}

# Git clone or pull if exists
git_ensure_repo() {
    local repo_url="$1"
    local target_dir="$2"

    if [ -d "$target_dir" ]; then
        log "Updating existing repo at $target_dir"
        git -C "$target_dir" pull || warn "Failed to pull update for $target_dir"
    else
        run_with_retry git clone "$repo_url" "$target_dir"
    fi
}

# Append to file if not exists
append_if_missing() {
    local line="$1"
    local file="$2"
    grep -qF -- "$line" "$file" || echo "$line" >> "$file"
}

# --- Installation Steps ---

step_setup_xcode() {
    # This usually requires interaction if not installed, but checking path helps
    if ! xcode-select -p &>/dev/null; then
        warn "Xcode Command Line Tools not found. Requesting install..."
        xcode-select --install
        echo "Please complete the Xcode installation dialog then press Enter."
        read
    else
        # Switch to CLI to assume license is accepted/paths are correct
        sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
}

step_install_homebrew() {
    if ! command -v brew &>/dev/null; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Add to path immediately for this session
    if [[ $(uname -m) == 'arm64' ]]; then
        test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        test -d /usr/local && eval "$(/usr/local/bin/brew shellenv)"
    fi
}

step_install_zsh_extras() {
    # Starship
    if ! command -v starship &>/dev/null; then
        run_with_retry sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
    fi

    # Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        run_with_retry sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    git_ensure_repo "https://github.com/zsh-users/zsh-history-substring-search" "$zsh_custom/plugins/zsh-history-substring-search"
    git_ensure_repo "https://github.com/zsh-users/zsh-autosuggestions" "$zsh_custom/plugins/zsh-autosuggestions"
    git_ensure_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$zsh_custom/plugins/zsh-syntax-highlighting"
    git_ensure_repo "https://github.com/Aloxaf/fzf-tab" "$zsh_custom/plugins/fzf-tab"
}

step_configure_zshrc() {
    local zshrc="$HOME/.zshrc"
    
    # Backup existing
    [ -f "$zshrc" ] && cp "$zshrc" "$zshrc.backup.$(date +%s)"

    # Overwrite zshrc with standard config
    cat <<'EOF' > "$zshrc"
# env
export VOLTA_HOME="$HOME/.volta"
export ZSH="$HOME/.oh-my-zsh"
export HERD_PHP_74_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/74/"
export HERD_PHP_80_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/80/"
export HERD_PHP_81_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/81/"
export HERD_PHP_82_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/82/"
export HERD_PHP_83_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/83/"
export HERD_PHP_84_INI_SCAN_DIR="$HOME/Library/Application Support/Herd/config/php/84/"
export PATH="$PATH:$VOLTA_HOME/bin:$HOME/Library/Application Support/Herd/bin:$HOME/.bin:$HOME/.local/bin"

# zsh plugins and completions
## define plugins to load
plugins=(
  fzf-tab
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

## set up completions path
fpath=(
  /opt/homebrew/share/zsh/site-functions
  /usr/local/share/zsh/site-functions
  $fpath
)

## initialize completions
autoload -Uz compinit && compinit

## zsh style
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select

## source oh my zsh
source $ZSH/oh-my-zsh.sh
eval "$(starship init zsh)"
EOF
}

step_vscode_extensions() {
    mkdir -p "$HOME/Library/Application Support/Code/User"
    run_with_retry curl -o "$HOME/Library/Application Support/Code/User/settings.json" \
        https://raw.githubusercontent.com/atabix/macbook-install/main/configs/vscode-settings.json
        
    local extensions=(
        alefragnani.project-manager
        amiralizadeh9480.laravel-extra-intellisense
        atabixsolutions.hephaestus
        bmewburn.vscode-intelephense-client
        bradlc.vscode-tailwindcss
        calebporzio.better-phpunit
        fireyy.vscode-language-todo
        ikappas.composer
        jaguadoromero.vscode-php-create-class
        junstyle.php-cs-fixer
        mehedidracula.php-namespace-resolver
        mohamedbenhida.laravel-intellisense
        mrmlnc.vscode-duplicate
        steoates.autoimport
        vue.volar
        waderyan.gitblame
        xdebug.php-debug
    )

    for ext in "${extensions[@]}"; do
        if command -v code >/dev/null && code --list-extensions | grep -q "$ext"; then
            log "Extension $ext already installed."
        else
            run_with_retry code --install-extension "$ext"
        fi
    done
}

step_brew_bundle_dev() {
    run_with_retry curl -o Brewfile https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-dev
    brew bundle install
    rm Brewfile
    git lfs install
}

step_brew_bundle_nondev() {
    run_with_retry curl -o Brewfile https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-nondev
    brew bundle install
    rm Brewfile
}

step_php_tools() {
    mkdir -p "$HOME/.bin"
    run_with_retry curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o "$HOME/.bin/php-cs-fixer"
    chmod +x "$HOME/.bin/php-cs-fixer"
    
    mkdir -p "$HOME/Development"
    run_with_retry curl -o "$HOME/Development/.php-cs-fixer.dist.php" \
        https://raw.githubusercontent.com/atabix/macbook-install/main/scripts/php-cs-fixer.dist.php
}

step_dev_notice() {
    run_with_retry curl -o "$HOME/dev-notice.md" \
        https://raw.githubusercontent.com/atabix/macbook-install/main/dev-notice.md
    if command -v code >/dev/null; then
        code "$HOME/dev-notice.md"
    else
        open "$HOME/dev-notice.md"
    fi
}

add_brew_path_zshrc() {
    if [[ $(uname -m) == 'arm64' ]]; then
        append_if_missing 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zshrc"
    else
        append_if_missing 'eval "$(/usr/local/bin/brew shellenv)"' "$HOME/.zshrc"
    fi
}

# --- Main Logic ---

# Initial Setup
echo "Starting Macbook Installation Script..."

# Determine Developer Mode
if [ -z ${DEVELOPER+x} ]; then 
    echo -n "Will this laptop be for a developer? [y/n] "
    read -k 1 REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        export DEVELOPER=true
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
        export DEVELOPER=false
    else
        error "Invalid input. Please set DEVELOPER=true or DEVELOPER=false manually or answer y/n."
        exit 1
    fi
fi

# Store selection in state file if it's new
if ! is_step_completed "mode_selection"; then
    echo "DEVELOPER_MODE=$DEVELOPER" >> "$STATE_FILE"
    mark_step_completed "mode_selection"
fi

# Base Steps (Common)
sudo -v # Refreshes sudo timestamp
execute_step "xcode_setup" step_setup_xcode "Xcode CLI Tools Setup"
execute_step "homebrew_install" step_install_homebrew "Homebrew Installation"

# Ensure brew is in path for script execution
if [[ $(uname -m) == 'arm64' ]]; then
    test -f /opt/homebrew/bin/brew && eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Fix permissions for Intel macs /usr/local
    sudo chown -R $(whoami) /usr/local/*
    test -f /usr/local/bin/brew && eval "$(/usr/local/bin/brew shellenv)"
fi

if [ "$DEVELOPER" = true ]; then
    log "Running Developer Installation..."
    
    execute_step "zsh_extras" step_install_zsh_extras "Zsh Framework & Plugins"
    execute_step "configure_zshrc" step_configure_zshrc "Zsh Configuration"
    execute_step "brew_bundle_dev" step_brew_bundle_dev "Brew Bundle (Developer)"
    execute_step "php_tools" step_php_tools "PHP CS Fixer Setup"
    execute_step "vscode_extensions" step_vscode_extensions "VS Code Extensions"
    execute_step "dev_notice" step_dev_notice "Show Developer Notice"
    
else
    log "Running Standard Installation..."
    
    # Non-devs also get zsh pathing for brew
    execute_step "zsh_brew_path" add_brew_path_zshrc "Add Brew to Zsh Path"
    execute_step "brew_bundle_nondev" step_brew_bundle_nondev "Brew Bundle (Standard)"
fi

success "Installation Complete! Please restart your terminal."
