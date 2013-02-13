#!/bin/bash

# Release script for 2013-Jan-1
#
# To be run as a sudo-enabled user
# 
# This script may be run as-is if you have imagefactory v2 running
# without oauth on localhost:8075
#

### BEGIN RELEASE-SPECIFIC VERSION DEFININTIONS

# Points to https://github.com/aeolus-incubator/dev-tools/commit/ce50b51336
export DEV_TOOLS_BRANCH=bb6aa09

# Points to https://github.com/aeolusproject/conductor/commit/f66ce6fb
export FACTER_CONDUCTOR_BRANCH=5420594
export SETUP_LOCAL_DELTACLOUD_RELEASE=release-1.1.0
export FACTER_TIM_BRANCH=v0.2.0
export RBENV_VERSION=1.9.3-p374

### END RELEASE-SPECIFIC VERSION DEFININTIONS


### BEGIN IMAGEFACTORY CONFIG

# The below variables assume imagefactory sans oauth on localhost:8075
export FACTER_CONDUCTOR_HOSTNAME=localhost
export FACTER_IMAGEFACTORY_URL=http://localhost:8075/imagefactory

### END IMAGEFACTORY CONFIG


### BEGIN DIRECTORY AND PORT DEFINITIONS

export WORKDIR=/home/$USER/aeolus-$DEV_TOOLS_BRANCH
export FACTER_CONDUCTOR_PORT=3000
export SETUP_LOCAL_DELTACLOUD_PORT=3002
export FACTER_DELTACLOUD_URL=http://localhost:3002/api

### END DIRECTORY AND PORT DEFINITIONS

curl https://raw.github.com/aeolus-incubator/dev-tools/$DEV_TOOLS_BRANCH/bootstrap.sh | /bin/bash 2>&1 | tee -a /tmp/bootstrap-$DEV_TOOLS_BRANCH.out
