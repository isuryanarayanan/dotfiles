#!/bin/bash

SUDO=''

if (( $EUID != 0 )); then
    echo "Please run as root"
		SUDO='sudo'
    exit
fi

$SUDO apt-get update -y
$SUDO apt-get upgrade -y
$SUDO apt-get install python3 python3-pip cmatrix tmux tmuxinator

echo "Purging Vim and installing Neovim"
$SUDO apt-get purge vim -y
$SUDO apt-get install neovim -y
curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plugg.vim --create-dirs \ 
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

$SUDO mkdir ~/.config/nvim && cp ./init.vim ~/.config/nvim/ 


#$SUDO cp ./.bash_aliases /home/isuryanarayanan/




