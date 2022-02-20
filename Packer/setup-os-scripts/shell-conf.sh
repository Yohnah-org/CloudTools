#!/bin/sh -eux
apt-get -y install zsh zsh-antigen python3-pip

chsh -s $(which zsh) vagrant

cat <<EOF > /home/vagrant/.zshrc
source $(dpkg -L zsh-antigen | grep -i "antigen.zsh")

antigen use oh-my-zsh

antigen bundle git
antigen bundle pip
antigen bundle lein
antigen bundle command-not-foun

antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting

antigen theme philips

antigen apply
EOF