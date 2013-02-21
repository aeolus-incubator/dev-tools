#!/bin/bash

# Release script for 2012-Dec-1
#
# To be run as a sudo-enabled user
# 
# You *must* have imagefactory v1.1.1 and iwhd v1.5 already installed
# On Fedora17 you have them in the official repositories
#

### BEGIN RELEASE-SPECIFIC VERSION DEFININTIONS

export DEV_TOOLS_BRANCH=2012-dec-1
export FACTER_CONDUCTOR_BRANCH=2012-Dec-1
export FACTER_AEOLUS_IMAGE_RUBYGEM_BRANCH=2012-Dec-1
export SETUP_LOCAL_DELTACLOUD_RELEASE=release-1.0.5
export RBENV_VERSION=1.9.3-p374

### END RELEASE-SPECIFIC VERSION DEFININTIONS


### BEGIN USER-REQUIRED CONFIGURATION

export FACTER_IWHD_URL=http://localhost:9090
export FACTER_IMAGEFACTORY_URL=http://localhost:8075/imagefactory 
export FACTER_OAUTH_JSON_FILE=/tmp/oauth.json

### END USER-REQUIRED CONFIGURATION


### BEGIN DIRECTORY AND PORT DEFINITIONS

export WORKDIR=~/aeolus-$DEV_TOOLS_BRANCH
export FACTER_DELTACLOUD_URL=http://localhost:3002/api

### END DIRECTORY AND PORT DEFINITIONS

curl https://raw.github.com/aeolus-incubator/dev-tools/2012-dec-1/bootstrap.sh | /bin/bash -x 2>&1 | tee -a /tmp/bootstrap-$DEV_TOOLS_BRANCH.out
