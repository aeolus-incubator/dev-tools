#!/bin/bash

# Release script for 0.14.x release branch
#
# To be run as a sudo-enabled user
# 
# This script assumes that imagefactory is *not* installed via RPM

### BEGIN ImageFactory instalation
# Install imagefactory 2 from repository

export WORKDIR=${WORKDIR:=~/aeolus-workdir}

os=unsupported

grep -qs -P 'Fedora release 17' /etc/fedora-release && os=f17
grep -qs -P 'Fedora release 18' /etc/fedora-release && os=f18

if [ "$os" = "unsupported" ]; then
  echo "ImageFactory install was not tested outside 17/18."
  echo "Please follow instructions at:"
  echo "https://github.com/aeolusproject/imagefactory/wiki/Installing-from-Source"
  echo "To install development libraries manually."
  echo
  echo "Press Control-C to quit, or ENTER to skip this step."
  read
else

  mkdir -p $WORKDIR
  cd $WORKDIR
  
  git clone git://github.com/aeolusproject/imagefactory.git
  
  if [ ! -d imagefactory ]; then
    echo "sorry, git checkut failed, retry later"
    exit 1
  fi
  
  cd imagefactory/
  git checkout f786e58
  make rpm
  
  cd imagefactory_plugins/; make rpm
  cd ~/rpmbuild/RPMS/noarch
  
  RPMS='imagefactory' # imagefactory-secondary'
  RPMS="$RPMS imagefactory-plugins imagefactory-plugins-FedoraOS imagefactory-plugins-OpenStackCloud imagefactory-plugins-EC2Cloud imagefactory-plugins-EC2Cloud-JEOS-images imagefactory-plugins-MockRPMBasedOS imagefactory-plugins-MockSphere imagefactory-plugins-vSphere imagefactory-plugins-RHEVM"
  
  # install everything *except* imagefactory-secondary which has a yum
  # error and only seems needed to get around a firewall, from the rpm desciption:
  #
  # Summary     : Remote/Secondary Image Factory functionality
  # Description :
  # Additional modules to allow the use of primary and secondary factories.
  # This is mainly useful when operating the primary factory behind a restrictive firewall.
  
  INSTALL=$(for p in $RPMS; do echo -n "${p}-1*rpm "; done)
  sudo yum install $INSTALL
  
  # Verify the dependencies did install
  fail_list=""
  for dep in $RPMS; do
    if ! `sudo rpm -q --quiet --nodigest $dep`; then
      fail_list="$fail_list $dep"
    fi
  done
  
  # If anything failed verification, we tell the user and exit
  if [ ! -z "$fail_list" ]; then
      echo "ABORTING:  FAILED TO INSTALL $fail_list"
      exit 1
  fi
  
  # imagefactory assumes libvirtd is already started
  sudo systemctl start libvirtd.service
  
  sudo grep -q -- '--debug --no_oauth --no_ssl' /etc/sysconfig/imagefactoryd || sudo sed -ie 's/--debug/--debug --no_oauth --no_ssl/g' /etc/sysconfig/imagefactoryd
  echo "starting image factory"
  sudo systemctl start imagefactoryd.service
fi

### END ImageFactory instalation

### BEGIN RELEASE-SPECIFIC VERSION DEFININTIONS

# Points to https://github.com/aeolus-incubator/dev-tools/commit/0.14.0
export DEV_TOOLS_BRANCH=0.14.0

# Points to https://github.com/aeolusproject/conductor/commit/f66ce6fb
export FACTER_CONDUCTOR_BRANCH=0.14.0
export SETUP_LOCAL_DELTACLOUD_RELEASE=release-1.1.1
export FACTER_TIM_BRANCH=v0.2.0
export RBENV_VERSION=1.9.3-p374

### END RELEASE-SPECIFIC VERSION DEFININTIONS


### BEGIN IMAGEFACTORY CONFIG

# The below variables assume imagefactory sans oauth on localhost:8075
export FACTER_CONDUCTOR_HOSTNAME=localhost
export FACTER_IMAGEFACTORY_URL=http://localhost:8075/imagefactory

### END IMAGEFACTORY CONFIG


### BEGIN DIRECTORY AND PORT DEFINITIONS

export WORKDIR=~/aeolus-$DEV_TOOLS_BRANCH
export FACTER_CONDUCTOR_PORT=3000
export SETUP_LOCAL_DELTACLOUD_PORT=3002
export FACTER_DELTACLOUD_URL=http://localhost:3002/api

### END DIRECTORY AND PORT DEFINITIONS

curl https://raw.github.com/aeolus-incubator/dev-tools/$DEV_TOOLS_BRANCH/bootstrap.sh | /bin/bash 2>&1 | tee -a /tmp/bootstrap-$DEV_TOOLS_BRANCH.out
