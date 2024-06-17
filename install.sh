#first install xcode in a terminal with "xcode-select --install" we can't do this in the script because the dialog won't make the script wait
#same here: if it's an arm64 based laptop (M1, M2, etc) run this command "sudo softwareupdate --install-rosetta"

#to run the script easily from the terminal, type: "export DEVELOPER=true; curl https://raw.githubusercontent.com/atabix/macbook-install/main/install.sh | zsh"

#bundle repeatable commands into functions
zsh_env_install() {
    #starship for zsh
    sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y
    #oh-my-zsh for zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab
    #fzf for zsh auto completion
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf && cd $HOME/.fzf && ./install --bin --no-update-rc --no-bash --no-zsh --no-fish && cd || exit
    #changing .zshrc
    echo "# plugins" > $HOME/.zshrc
    echo "plugins=(" >> $HOME/.zshrc
    echo "docker" >> $HOME/.zshrc
    echo "fzf-tab" >> $HOME/.zshrc
    echo "git" >> $HOME/.zshrc
    echo "zsh-autosuggestions" >> $HOME/.zshrc
    echo "zsh-history-substring-search" >> $HOME/.zshrc
    echo "zsh-syntax-highlighting" >> $HOME/.zshrc
    echo ")" >> $HOME/.zshrc
    echo "# omz" >> $HOME/.zshrc
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> $HOME/.zshrc
    echo 'source $ZSH/oh-my-zsh.sh' >> $HOME/.zshrc
    echo "# alias" >> $HOME/.zshrc
    echo 'alias ls="ls -hplav --color=always"' >> $HOME/.zshrc
    echo "# env" >> $HOME/.zshrc
    echo 'export PATH="$PATH:$HOME/.fzf/bin"' >> $HOME/.zshrc
    echo "# inits" >> $HOME/.zshrc
}
vscode_extensions() {
    #install vscode extensions
    code --install-extension alefragnani.project-manager
    code --install-extension amiralizadeh9480.laravel-extra-intellisense
    code --install-extension atabixsolutions.hephaestus
    code --install-extension bmewburn.vscode-intelephense-client
    code --install-extension bradlc.vscode-tailwindcss
    code --install-extension calebporzio.better-phpunit
    code --install-extension coenraads.disableligatures
    code --install-extension fireyy.vscode-language-todo
    code --install-extension ikappas.composer
    code --install-extension jaguadoromero.vscode-php-create-class
    code --install-extension jeff-hykin.better-syntax
    code --install-extension junstyle.php-cs-fixer
    code --install-extension ldd-vs-code.better-package-json
    code --install-extension mehedidracula.php-namespace-resolver
    code --install-extension mikestead.dotenv
    code --install-extension mohamedbenhida.laravel-intellisense
    code --install-extension mrmlnc.vscode-apache
    code --install-extension mrmlnc.vscode-duplicate
    code --install-extension steoates.autoimport
    code --install-extension vscode-icons-team.vscode-icons
    code --install-extension vue.volar
    code --install-extension waderyan.gitblame
    code --install-extension xdebug.php-debug
}
dev_extras() {
    #install tools with brew
    cd || exit
    curl -O https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-dev
    mv Brewfile-dev Brewfile
    brew bundle install
    source $HOME/.zshrc

    #install lfs for git
    git lfs install

    #volta
    curl https://get.volta.sh | bash
    $HOME/.volta/bin/volta install node
}
brew_autoupdate() {
    #make brew autoupdate
    brew tap homebrew/autoupdate
    mkdir -p $HOME/Library/LaunchAgents
    source $HOME/.zshrc
    brew autoupdate start 86400 --upgrade --greedy --cleanup --enable-notification
}

#detect if developer variable has been set
if [ -z ${DEVELOPER+x} ]; then 
    echo "Please choose if this laptop will be a developer laptop or not!"; exit;
fi
if [ "$DEVELOPER" = true ]; then
    echo Developer laptop
    if [[ $(uname -m) == 'arm64' ]]; then
        echo ARM detected
        echo "Install step: 1.0"
        zsh_env_install

        #brew noninteractive install
        echo "Install step: 1.1"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zshrc

        #tell macos to not index these folders
        [ ! -d "$HOME/Development" ] && mkdir -p $HOME/Development
        touch $HOME/Development/.metadata_never_index
        touch /opt/homebrew/.metadata_never_index

        echo "Install step: 1.2"
        dev_extras

        #php cs fix
        echo "Install step: 1.3"
        mkdir -p /opt/homebrew/lib/php-cs-fixer
        composer require --dev --working-dir=/opt/homebrew/lib/php-cs-fixer friendsofphp/php-cs-fixer
        ln -s /opt/homebrew/lib/php-cs-fixer/vendor/bin/php-cs-fixer /opt/homebrew/bin/php-cs-fixer
        curl https://raw.githubusercontent.com/atabix/macbook-install/main/assets/scripts/php-cs-fixer.dist.php > $HOME/Development/.php-cs-fixer.dist.php

        echo "Install step: 1.4"
        vscode_extensions

        #make starship work
        echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc

        echo "Install step: 1.5"
        brew_autoupdate
    fi
    if [[ $(uname -m) == 'x86_64' ]]; then
        echo x86_64 detected
        echo "Install step: 1.0"
        zsh_env_install
        #fix /usr/local permissions after starship install, this is only needed on intel macs because intel homebrew installs to /usr/local
        sudo chown -R $(whoami) /usr/local/*

        #brew noninteractive install
        echo "Install step: 1.1"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/usr/local/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zshrc

        #tell macos to not index these folders
        [ ! -d "$HOME/Development" ] && mkdir -p $HOME/Development
        touch $HOME/Development/.metadata_never_index

        echo "Install step: 1.2"
        dev_extras

        #php cs fix
        echo "Install step: 1.3"
        mkdir -p $HOME/.php-cs-fixer
        composer require --dev --working-dir=$HOME/.php-cs-fixer friendsofphp/php-cs-fixer
        echo 'export PATH="$PATH:$HOME/.php-cs-fixer/vendor/bin' >> $HOME/.zshrc
        curl https://raw.githubusercontent.com/atabix/macbook-install/main/assets/scripts/php-cs-fixer.dist.php > $HOME/Development/.php-cs-fixer.dist.php

        echo "Install step: 1.4"
        vscode_extensions

        #make starship work
        echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc

        echo "Install step: 1.5"
        brew_autoupdate
    fi
fi
if [ "$DEVELOPER" = false ]; then
    echo Non-developer laptop
    if [[ $(uname -m) == 'arm64' ]]; then
        echo ARM detected
        #brew noninteractive install
        echo "Install step: 1.0"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zshrc

        #tell macos to not index these folders
        touch /opt/homebrew/.metadata_never_index

        #install tools with brew
        echo "Install step: 1.1"
        cd || exit
        curl -O https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-nondev
        mv Brewfile-nondev Brewfile
        brew bundle install
        source $HOME/.zshrc

        echo "Install step: 1.2"
        brew_autoupdate
    fi
    if [[ $(uname -m) == 'x86_64' ]]; then
        echo x86_64 detected
        #brew noninteractive install
        echo "Install step: 1.0"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/usr/local/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zshrc

        #install tools with brew
        echo "Install step: 1.1"
        cd || exit
        curl -O https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-nondev
        mv Brewfile-nondev Brewfile
        brew bundle install
        source $HOME/.zshrc

        echo "Install step: 1.2"
        brew_autoupdate
    fi
fi
