#!/usr/bin/env bash
#
# bootstrap.sh will check for and install any dependencies we have for building and using iofogctl
#
# Usage: ./bootstrap.sh
#


set -e

# Import our helper functions
. script/utils.sh

prettyTitle "Installing iofogctl Dependencies"
echo

# What platform are we on?
OS=$(uname -s | tr A-Z a-z)
K8S_VERSION=1.13.4

# Check whether Brew is installed
# TODO: Current installation method is macos centric, make it work for linux too.
#if ! checkForInstallation "brew"; then
#    echoInfo " Attempting to install Brew"
#    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#fi


#
# All our Go related stuff
#

# Is go installed?
if ! checkForInstallation "go"; then
    echoNotify "\nYou do not have Go installed. Please install and re-run bootstrap."
    exit 1
fi

# Is dep installed?
if ! checkForInstallation "dep"; then
    echoInfo " Attempting to install 'go dep'"
    go get -u github.com/golang/dep/cmd/dep
fi

# Is go-junit-report installed?
if ! checkForInstallation "go-junit-report"; then
    echoInfo " Attempting to install 'go-junit-report'"
    go get -u github.com/jstemmer/go-junit-report
fi

# Is bats installed?
if ! checkForInstallation "bats"; then
    echoInfo " Attempting to install 'bats'"
    git clone https://github.com/sstephenson/bats.git && cd bats && sudo ./install.sh /usr/local
fi

#
# All our Kubernetes related stuff
##
#

## Is kubernetes-cli installed?
if ! checkForInstallation "kubectl"; then
    echoInfo " Attempting to install kubernetes-cli"
	curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v"$K8S_VERSION"/bin/"$OS"/amd64/kubectl
	chmod +x kubectl
	sudo mv kubectl /usr/local/bin/
fi