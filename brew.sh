#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install Bash 4.
# Note: don’t forget to add `/usr/local/bin/bash` to `/etc/shells` before
# running `chsh`.
brew install bash
brew tap homebrew/versions
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q '/usr/local/bin/bash' /etc/shells; then
  echo '/usr/local/bin/bash' | sudo tee -a /etc/shells;
  chsh -s /usr/local/bin/bash;
fi;

# Install `wget` with IRI support.
brew install wget --with-iri

# Install more recent versions of some OS X tools.

# Install RingoJS and Narwhal.
# Note that the order in which these are installed is important;
# see http://git.io/brew-narwhal-ringo.
brew install ringojs
brew install narwhal

# Install more recent versions of some macOS tools.
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
brew install vim --with-override-system-vi
brew install homebrew/dupes/grep
brew install homebrew/dupes/openssh
brew install homebrew/dupes/screen
brew install homebrew/php/php56 --with-gmp

# Install font tools.
brew tap bramstein/webfonttools
brew install sfnt2woff
brew install sfnt2woff-zopfli
brew install woff2

# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew install aircrack-ng
brew install bfg
brew install binutils
brew install binwalk
brew install cifer
brew install dex2jar
brew install dns2tcp
brew install fcrackzip
brew install foremost
brew install hashpump
brew install hydra
brew install john
brew install knock
brew install netpbm
brew install nmap
brew install pngcheck
brew install socat
brew install sqlmap
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install ucspi-tcp # `tcpserver` etc.
brew install xpdf
brew install xz

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

# Install Node.js & io.js through n
function doIt1() {
	brew install n;
}

function doIt2() {
	n stable;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt1;
	doIt2;
else
	read -p "Do you want install n? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt1;
	fi;
	read -p "o you want install Node.js? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt2;
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
