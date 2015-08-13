# install ssh
sudo apt-get install  openssh-server openssh-client

# install Mercurial (hg)
sudo add-apt-repository ppa:tortoisehg-ppa/releases
sudo add-apt-repository ppa:mercurial-ppa/releases
sudo apt-get update
#sudo apt-get install mercurial python-nautilus tortoisehg
sudo apt-get install mercurial

# remove message icon
sudo apt-get remove indicator-messages -y

# install unity-tweak-tool
sudo apt-get install unity-tweak-tool

sudo touch /etc/default/google-chrome
