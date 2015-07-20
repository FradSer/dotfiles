#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Install Homebrew.
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade --all

# Install `wget` with IRI support.
brew install wget --with-iri

# Install more recent versions of some OS X tools.
brew install vim --override-system-vi
brew install curl
brew install grep
brew install openssh
brew install screen
brew install rsync
brew install whois
brew install tcl-tk
brew install gzip
brew install unzip
brew install make


# Install other useful binaries.
brew install ack
brew install exiv2
brew install thefuck
brew install gnupg
brew install git
brew install git-lfs
brew install imagemagick --with-webp
brew install lynx
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install speedtest_cli
brew install ssh-copy-id
brew install tree
brew install zopfli

# Install Node.js
brew install node
exec $SHELL -l # Reload the shell
npm install -g n
n stable
brew remove node
brew prune

# Insatll RVM and stable Ruby
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.profile
rm ~/.profile
rvm install ruby-head

# Install Python & Python 3
brew install python
brew install python3

# Remove outdated versions from the cellar.
brew cleanup

# Message
echo "Congratulations! You are installed Homebrew & more recent versions of some OS X tools &  some useful binaries & Node.js with n & Ruby with RVM & Python & Python 3."
