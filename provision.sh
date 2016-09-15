#!/bin/bash
# Provisioning script for Vagrant.
# 
# Installs the following software:
# - NodeJS
# - MySQL

# Functions
function print {
	echo -e $1;
}

function backupFile {
	local original=${1:-}
	if [[ -e "${original}" ]]; then
		local destination="${original}.orig"
		local i=0
		if [[ -e "${destination}" ]]; then
			while [[ -e "${original}-${i}.orig" ]]; do
				i=$((i+1))
			done
			destination="${original}-${i}.orig"
		fi
		print "Backing up file '${original}' to '${destination}'."
		cp "${original}" "${destination}"
	fi
}

# Check if script is running as root.
if [[ $EUID -ne 0 ]]; then
	print "This script requires root privileges to continue. Provisioning failed." error
	exit
fi

# Enable stricter bash requirements.
set -euo pipefail
IFS=$'\n\t'

# Create temporary working directory.
temporaryDirectory="$(mktemp -d -t tmp-install.XXXXXXXXXXX)"
cd "${temporaryDirectory}"

function cleanup {
	print "Installation script cleanup in progress."
	rm -rf "${temporaryDirectory}"
}

# Define abnormal exit conditions.
function errorexit {
	print "An error occurred during the installation." error
	cleanup
}
trap errorexit EXIT

function interruptexit {
	print "\n\nInstallation process interrupted." error
	cleanup
	trap - EXIT
	exit
}
trap interruptexit SIGINT
trap interruptexit SIGTERM

function installOSUpdates {
	# APT update and upgrade any packages.
	print "Getting operating system updates."
	apt-get -o Acquire::ForceIPv4=true --yes update
	print "Updating the operating system."
	apt-get -o Acquire::ForceIPv4=true --yes upgrade
	apt-get -o Acquire::ForceIPv4=true --yes dist-upgrade
	print "Cleaning up update."
	apt-get -o Acquire::ForceIPv4=true --yes clean
	apt-get -o Acquire::ForceIPv4=true --yes autoclean
}

function installOSDependencies {
	# APT install required packages.
	print "Installing operating system dependencies."
	local i=0
	local dependencies=(
		"curl"
	)
	local numberDependencies=${#dependencies[@]}
	for (( i=0; i<${numberDependencies}; i++ ));
	do
		print "Installing dependency $((i+1)) of ${numberDependencies}, ${dependencies[$i]}."
		apt-get -o Acquire::ForceIPv4=true --yes install ${dependencies[$i]}
	done
}

function installNodeJS {
	curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
	cat <<EOF >> /etc/apt/sources.list.d/nodesource.list
	deb https://deb.nodesource.com/node_4.x trusty main
	deb-src https://deb.nodesource.com/node_4.x trusty main
EOF
	apt-get -o Acquire::ForceIPv4=true --yes update
	apt-get -o Acquire::ForceIPv4=true --yes install nodejs
}

function installMySQL {
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
	sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
	sudo -E apt-get -q -o Acquire::ForceIPv4=true --yes install mysql-server
}

function finish {
	print "Installation completed successfully."
	print "Please give us a moment to do some final housekeeping."
	trap - EXIT
	trap - SIGINT
	trap - SIGTERM
	cleanup
	exit
}

installations=(
	"installOSUpdates"
	"installOSDependencies"
	"installNodeJS"
	"installMySQL"
	"finish"
)

numberInstallables=${#installations[@]}
for (( i=0; i<${numberInstallables}; i++ ));
do
	print "+*****************+\nInstallation phase $((i+1)) of ${numberInstallables}.\n+*****************+"
	${installations[$i]}
done
