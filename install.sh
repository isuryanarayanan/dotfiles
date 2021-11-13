#!/bin/bash

SUDO=''

if (( $EUID != 0 )); then
    echo "Please run as root"
		SUDO='sudo'
    exit
fi

# Creating the main user

if [ $(id -u) -eq 0 ]; then
	read -p "Enter username : " username
	read -s -p "Enter password : " password
	egrep "^$username" /etc/passwd >/dev/null
	if [ $? -eq 0 ]; then
		echo "$username exists!"
		exit 1
	else
		pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
		useradd -m -p "$pass" "$username"
		[ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
	fi
else
	echo "Only root may add a user to the system."
	exit 2
fi

$SUDO usermod -aG sudo $username

echo "-----------------"
echo "Generating ssh keys"
echo "-----------------"
#$SUDO runuser -l $username -c ""
read -p "Enter git username: " gitusername
read -p "Enter git email: " gitemail
$SUDO runuser -l $username -c "git config --global user.name '$gitusername'"
$SUDO runuser -l $username -c "git config --global user.email '$gitemail'"
$SUDO runuser -l $username -c "ssh-keygen -b 2048 -t rsa -f /home/$username/ssh_keys -q -N '' && cat /home/$username/ssh_keys.pub"

echo "-----------------"
echo "Installing Dependencies"
echo "-----------------"
$SUDO runuser -l $username -c "echo $password | sudo -S dpkg --configure -a"
$SUDO runuser -l $username -c "echo $password | sudo -S apt install python3 python3-pip cmatrix tmux tmuxinator neovim"

echo "-----------------"
echo "Setting Up Nodejs"
echo "-----------------"
$SUDO runuser -l $username -c "echo $password | sudo -S curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
$SUDO runuser -l $username -c "echo $password | sudo -S source ~/.bashrc && nvm install node"

echo "-----------------"
echo "Setting Up NeoVim"
echo "-----------------"
$SUDO runuser -l $username -c "echo $password | sudo -S mkdir ~/.config "
$SUDO runuser -l $username -c "echo $password | sudo -S mkdir ~/.config/nvim/"
$SUDO runuser -l $username -c "echo $password | sudo -S mkdir ~/.config/nvim/autoload/"
$SUDO runuser -l $username -c "echo $password | sudo -S touch ~/.config/nvim/init.vim"
$SUDO runuser -l $username -c "echo $password | sudo -S touch ~/.config/nvim/autoload/plug.vim"
$SUDO runuser -l $username -c "echo $password | sudo -S curl https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim -o ~/.config/nvim/autoload/plug.vim "
$SUDO runuser -l $username -c "echo $password | sudo -S curl https://raw.githubusercontent.com/isuryanarayanan/dotfiles/master/init.vim -o ~/.config/nvim/init.vim "

echo "-----------------"
echo "Setting Up Tmuxinator tools"
echo "-----------------"
$SUDO runuser -l $username -c "git clone https://github.com/isuryanarayanan/tmuxinator-fzf-helper.git && chmod +x tmuxinator-fzf-helper/tmuxinator-helper.sh"

echo "-----------------"
echo "Setting Up aliases"
echo "-----------------"
$SUDO runuser -l $username -c "git clone https://github.com/isuryanarayanan/dotfiles.git"
$SUDO runuser -l $username -c "cp ~/dotfiles/.bash_aliases ~/.bash_aliases && source ~/.bashrc"
