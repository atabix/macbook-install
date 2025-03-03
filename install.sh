#first install xcode in a terminal with "xcode-select --install" we can't do this in the script because the dialog won't make the script wait
#same here: if it's an arm64 based laptop (M1, M2, etc) run this command "sudo softwareupdate --install-rosetta"

#to run the script easily from the terminal, type: "curl https://raw.githubusercontent.com/atabix/macbook-install/main/install.sh | zsh"

#prompt to ask if this will be a developer laptop or not
echo -n "Will this laptop be for a developer? [y/n]"
read -k 1 REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    export DEVELOPER=true
elif [[ $REPLY =~ ^[Nn]$ ]]
then
    export DEVELOPER=false
fi

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
    echo "brew" >> $HOME/.zshrc
    echo "docker" >> $HOME/.zshrc
    echo "fzf-tab" >> $HOME/.zshrc
    echo "git" >> $HOME/.zshrc
    echo "zsh-autosuggestions" >> $HOME/.zshrc
    echo "zsh-history-substring-search" >> $HOME/.zshrc
    echo "zsh-syntax-highlighting" >> $HOME/.zshrc
    echo ")" >> $HOME/.zshrc
    echo "# omz" >> $HOME/.zshrc
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> $HOME/.zshrc
    echo "# alias" >> $HOME/.zshrc
    echo 'alias ls="ls -hplav --color=always"' >> $HOME/.zshrc
    echo "# env" >> $HOME/.zshrc
    echo 'export PATH="$PATH:$HOME/.fzf/bin:$HOME/.bin:$HOME/Library/Application Support/Herd/bin:$HOME/.composer/vendor/bin"' >> $HOME/.zshrc
    echo 'source $ZSH/oh-my-zsh.sh' >> $HOME/.zshrc
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zshrc
    fi
    if [[ $(uname -m) == 'x86_64' ]]; then
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zshrc
    fi
    echo 'FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"' >> $HOME/.zshrc
}
vscode_extensions() {
    #populate vscode config with default settings before extensions so we don't overwrite anything
    mkdir -p $HOME/Library/Application\ Support/Code/User
    curl -o $HOME/Library/Application\ Support/Code/User/settings.json https://raw.githubusercontent.com/atabix/macbook-install/main/configs/vscode-settings.json
    #install vscode extensions
    code --install-extension alefragnani.project-manager
    code --install-extension amiralizadeh9480.laravel-extra-intellisense
    code --install-extension atabixsolutions.hephaestus
    code --install-extension bmewburn.vscode-intelephense-client
    code --install-extension bradlc.vscode-tailwindcss
    code --install-extension calebporzio.better-phpunit
    code --install-extension fireyy.vscode-language-todo
    code --install-extension ikappas.composer
    code --install-extension jaguadoromero.vscode-php-create-class
    code --install-extension junstyle.php-cs-fixer
    code --install-extension mehedidracula.php-namespace-resolver
    code --install-extension mohamedbenhida.laravel-intellisense
    code --install-extension mrmlnc.vscode-duplicate
    code --install-extension steoates.autoimport
    code --install-extension vue.volar
    code --install-extension waderyan.gitblame
    code --install-extension xdebug.php-debug
}
dev_extras() {
    #install tools with brew
    cd || exit
    curl -o Brewfile https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-dev
    brew bundle install
    source $HOME/.zshrc
    rm Brewfile

    #install lfs for git
    git lfs install
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
        #run sudo for the first time so that homebrew will detect it later
        sudo whoami
        #switch xcode to cli so that the license is accepted
        sudo xcode-select --switch /Library/Developer/CommandLineTools
        zsh_env_install

        #brew noninteractive install
        echo "Install step: 1.1"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"

        echo "Install step: 1.2"
        dev_extras

        #php cs fix
        echo "Install step: 1.3"
        mkdir -p $HOME/.bin
        curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o $HOME/.bin/php-cs-fixer
        chmod +x $HOME/.bin/php-cs-fixer
        curl -o $HOME/Development/.php-cs-fixer.dist.php https://raw.githubusercontent.com/atabix/macbook-install/main/scripts/php-cs-fixer.dist.php

        echo "Install step: 1.4"
        vscode_extensions

        #make starship work
        echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc
    fi
    if [[ $(uname -m) == 'x86_64' ]]; then
        echo x86_64 detected
        echo "Install step: 1.0"
        #run sudo for the first time so that homebrew will detect it later
        sudo whoami
        #switch xcode to cli so that the license is accepted
        sudo xcode-select --switch /Library/Developer/CommandLineTools
        zsh_env_install
        #fix /usr/local permissions, this is only needed on intel macs because intel homebrew installs to /usr/local
        sudo chown -R $(whoami) /usr/local/*

        #brew noninteractive install
        echo "Install step: 1.1"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/usr/local/bin/brew shellenv)"

        echo "Install step: 1.2"
        dev_extras

        #php cs fix
        echo "Install step: 1.3"
        mkdir -p $HOME/.bin
        curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o $HOME/.bin/php-cs-fixer
        chmod +x $HOME/.bin/php-cs-fixer
        curl -o $HOME/Development/.php-cs-fixer.dist.php https://raw.githubusercontent.com/atabix/macbook-install/main/scripts/php-cs-fixer.dist.php

        echo "Install step: 1.4"
        vscode_extensions

        #make starship work
        echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc
    fi
fi
if [ "$DEVELOPER" = false ]; then
    echo Non-developer laptop
    if [[ $(uname -m) == 'arm64' ]]; then
        echo ARM detected
        #run sudo for the first time so that homebrew will detect it later
        sudo whoami
        #switch xcode to cli so that the license is accepted
        sudo xcode-select --switch /Library/Developer/CommandLineTools
        #brew noninteractive install
        echo "Install step: 1.0"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zshrc

        #install tools with brew
        echo "Install step: 1.1"
        cd || exit
        curl -o Brewfile https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-nondev
        brew bundle install
        source $HOME/.zshrc
        rm Brewfile
    fi
    if [[ $(uname -m) == 'x86_64' ]]; then
        echo x86_64 detected
        #run sudo for the first time so that homebrew will detect it later
        sudo whoami
        #switch xcode to cli so that the license is accepted
        sudo xcode-select --switch /Library/Developer/CommandLineTools
        #fix /usr/local permissions, this is only needed on intel macs because intel homebrew installs to /usr/local
        sudo chown -R $(whoami) /usr/local/*
        #brew noninteractive install
        echo "Install step: 1.0"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/usr/local/bin/brew shellenv)"

        #add brew binary to zsh path
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zshrc

        #install tools with brew
        echo "Install step: 1.1"
        cd || exit
        curl -o Brewfile https://raw.githubusercontent.com/atabix/macbook-install/main/Brewfile-nondev
        brew bundle install
        source $HOME/.zshrc
        rm Brewfile
    fi
fi
