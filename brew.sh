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
brew install ag #Code-search similar to ack
brew install apparix # File system navigation via bookmarking directories.
brew install dark-mode # Toggle the Dark Mode (in OS X 10.10) from the command-line
brew install exiv2 # Open source Exif, IPTC and XMP metadata library and tools with Exif MakerNote and read/write support.
brew install thefuck # thefuck - Magnificent app which corrects your previous console command.
brew install gnupg # The GNU Privacy Guard (GnuPG) is a free replacement for PGP.
brew install git # Git
brew install git-lfs # Git Large File Storage (LFS) replaces large files such as audio samples, videos, datasets, and graphics with text pointers inside Git, while storing the file contents on a remote server like GitHub.com or GitHub Enterprise.
brew install imagemagick --with-webp # ImageMagick® is a software suite to create, edit, compose, or convert bitmap images.
brew install lynx # Lynx is the text web browser.
brew install p7zip # A command line port of the 7zip utility to Unix, Mac OS X and BeOS.
brew install pigz # A parallel implementation of gzip for modern multi-processor, multi-core machines.
brew install pv # pv - monitor the progress of data through a pipe.
brew install rename # Perl-powered file rename script with many helpful built-ins.
brew install speedtest_cli # Command-line interface for http://speedtest.net bandwidth tests.
brew install ssh-copy-id # Add a public key to a remote machine's authorized_keys file.
brew install tree # Display directories as trees (with optional color/HTML output).
brew install zopfli # New zlib (gzip, deflate) compatible compressor.

# Install n & node
function doIt1() {
	curl -L http://git.io/n-install | bash;
	exec $SHELL -l; # Reload the shell
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt1;
else
	read -p "Do you want install Node.js through n? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt1;
	fi;
fi;
unset doIt;

# Insatll RVM and stable Ruby
function doIt() {
	gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3;
	\curl -sSL https://get.rvm.io | bash -s stable;
	source ~/.profile;
	rm ~/.profile;
	rvm install ruby-head;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "Do you want install Ruby through RVM? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;

# Insatll Python 3
function doIt1() {
	brew install python
}

function doIt2() {
	brew install python3
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt1;
	doIt2;
else
	read -p "Do you also want install Python? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt1;
	fi;
	read -p "Do you also want install Python 3? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt2;
	fi;
fi;
unset doIt1;
unset doIt2;

# Remove outdated versions from the cellar.
brew cleanup

# Message
echo "Congratulations! You are installed Homebrew & more recent versions of some OS X tools &  some useful binaries & Node.js with n & Ruby with RVM & Python & Python 3."

# Use brew-doctor
brew doctor
