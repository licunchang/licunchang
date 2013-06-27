#!/bin/bash
#
# description    init linux mint 15
# author         LiCunchang(printf@live.com)
# version        1.0.20130624

if [[ "${whoami}" != "root" ]]; then
    echo "Sorry, you must run as root."
    echo "..."
    echo "How to enable the root account?"
    echo "> sudo passwd root"
    exit 1
fi

mkdir -p /home/licunchang/go/pkg
mkdir -p /home/licunchang/go/src
mkdir -p /home/licunchang/go/bin

apt-get update
apt-get -u dist-upgrade
apt-get clean

apt-get install gcc tree openssh-server ibus gedit dstat mercurial

# Git configuration
git config --global user.name "licunchang"
git config --global user.email printf@live.com
git config --global core.autocrlf false
git config --global color.ui auto
git config --global core.ignorecase false

# uninstall vim-tiny & install full vim
apt-get remove vim-tiny
apt-get install vim

# install go
mv /home/licunchang/Downloads/go/ /usr/local/
# install Sublime text 2
mv /home/licunchang/Downloads/Sublime\ Text\ 2 /usr/local/

# Golang syntax highlight
mkdir -p /home/licunchang/.vim/syntax
mkdir -p /home/licunchang/.vim/ftdetect
cp $GOROOT/misc/vim/syntax/go.vim /home/licunchang/.vim/syntax/
cp $GOROOT/misc/vim/syntax/go.vim /home/licunchang/.vim/ftdetect/

# Vim configuration
cat > /home/licunchang/.vimrc <<'EOF'
colorscheme evening

syntax enable
syntax on
filetype on

" http://stackoverflow.com/questions/235439/vim-80-column-layout-concerns
highlight OverLength ctermbg=red ctermfg=white guibg=#592929
match OverLength /\%>80v.\+/

set hlsearch
set confirm
set ignorecase
set showmode
set showmatch
set number
set nocompatible
set autoindent
set smartindent
set ruler

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

set laststatus=2
EOF

cat > /home/licunchang/.bashrc <<'EOF'
# Golang environment setting
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# User specific aliases
alias ll='ls -l --color=tty'

# `history` timestamp setting
export HISTTIMEFORMAT="%F %T: "
EOF

cat >> /etc/hosts <<'EOF'
173.194.71.141  golang.org
EOF

#sudo dpkg-reconfigure dash

touch /etc/default/google-chrome

cp /home/licunchang/Downloads/SourceCodePro_FontsOnly-1.017/OTF/* /usr/share/fonts/
fc-cache

# Sublime text 2 p.c.i
# import urllib2,os; pf='Package Control.sublime-package'; ipp=sublime.installed_packages_path(); os.makedirs(ipp) if not os.path.exists(ipp) else None; urllib2.install_opener(urllib2.build_opener(urllib2.ProxyHandler())); open(os.path.join(ipp,pf),'wb').write(urllib2.urlopen('http://sublime.wbond.net/'+pf.replace(' ','%20')).read()); print('Please restart Sublime Text to finish installation')

# apt-get warning: No support for locale: en_US.utf8
dpkg-reconfigure locales
update-locale LANG=en_US.UTF-8

# enable root
# sudo passwd root

# time
sed -i "s/^UTC=yes/UTC=no/" /etc/default/rcS

# turn off the monitor
xset dpms force off

# uninstall ufw firewall software
#sudo ufw disable
#sudo apt-get remove ufw
#sudo apt-get purge ufw

#dpkg -l | grep iptables
#sudo iptables -L

# KVM
egrep '(vmx|svm)' --color=always /proc/cpuinfo

# vi /etc/default/grub
# GRUB_TIMEOUT=3

# clean up /boot
dpkg --get-selections | grep linux-image
uname -a
apt-get purge linux-image-3.8.0-19-generic
cd /usr/src
rm -rf linux-headers-3.8.0-19

# setting http proxy
# export http_proxy=http://192.168.88.78:8087
# export https_proxy=http://192.168.88.78:8087






# KVM
sudo apt-get install qemu-kvm

mkdir -p /home/licunchang/VMachines

qemu-img create -f raw /home/licunchang/VMachines/CentOS-6.4-x86_64-10_10_10_10.img 10G

qemu-system-x86_64 -drive file=/home/licunchang/VMachines/CentOS-6.4-x86_64-10_10_10_10.img -cdrom /home/licunchang/Downloads/CentOS-6.4-x86_64-bin-DVD1.iso -boot d -m 2048

qemu-system-x86_64 -drive file=/home/licunchang/VMachines/CentOS-6.4-x86_64-10_10_10_10.img -cdrom /home/licunchang/Downloads/CentOS-6.4-x86_64-bin-DVD1.iso -boot c -m 2048

# boot from cdrom using iso image resource
# memery is 2048MB
# image file is /home/licunchang/VMachines/CentOS-6.4-x86_64-10_10_10_10.img